###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Encryption
  class Pluck
    attr_accessor :column_names
    attr_accessor :context
    attr_accessor :relation
    attr_accessor :simple
    attr_accessor :transformers
    attr_accessor :model_with_encryption
    attr_accessor :encrypted_column

    def initialize(column_names, context:, relation:, simple: false)
      self.column_names = column_names
      self.context = context
      self.relation = relation
      self.simple = simple
      self.transformers = []
    end

    # This makes it easier to reason about the parameters passed in to pluck.
    # A sort of normalization step
    def modified_request
      @modified_request ||=
        Array(column_names).flatten.map do |column|
          if column.respond_to?(:to_sql)
            column.to_sql
          elsif column.is_a?(Symbol)
            %<"#{column}">
          elsif column.match(/^".+"$/)
            column
          else
            %<"#{column}">
          end
        end
    end

    def transformed_columns
      # Build actual request with the procs needed to extract the value we need
      # e.g. [:FirstName, :email] would become [:encrypted_FirstName, :encrypted_FirstName_iv, :email]
      original_column_offset = -1
      modified_request.flat_map do |column|
        original_column_offset += 1

        if encrypted_match?(column)
          transformers << decrypter
          at = model_with_encryption.arel_table
          [
            at[model_with_encryption.encrypted_attributes.dig(self.encrypted_column, :attribute).to_sym],
            at["#{model_with_encryption.encrypted_attributes.dig(self.encrypted_column, :attribute)}_iv".to_sym],
          ]
        else
          transformers << ->(x) { x }
          self.column_names[original_column_offset]
        end
      end
    end

    def transformed_values(records)
      response = records.map do |record|
        i = 0
        transformers.map do |func|
          # the no-op proc take one argument and returns itself (e.g. ['hello@example.com'] -> 'hello@example.com')
          # the decryption proc takes two arguments and returns the cleartext value
          #    (e.g. ['b0xuGX8Df/g3pBYU7yj1BSgi0ao=', 'N12CmX0LkO3YQhLE'] -> 'John')
          column_values = Array(record)[i,func.arity]

          # This proc "consumed" this many of the raw results in the record.
          # 1 or 2 in practice
          i += func.arity

          # Transform it
          func.call(*column_values)
        end
      end

      # requesting one column just returns all the values in a 1D array
      # requesting two or more columns returns an array of arrays of values
      # e.g. pluck(:name) -> ['Ted', 'Bill', 'Sam']
      # e.g. pluck(:name, :age) -> [['Ted', 14], ['Bill', 18], ['Sam', 42]]
      if modified_request.length == 1
        response.flatten
      else
        response
      end
    end

    def encrypted_match?(column)
      reg_match = column.match(/"(?<table>.+)"\."(?<column>.+)"( AS.+)?/)
      reg_match ||= column.match(/(?<table>)"(?<column>.+)"/)

      self.encrypted_column = reg_match[:column].to_sym

      if simple && self.encrypted_column.in?(context.encrypted_attributes.keys)
        self.model_with_encryption = context
        true
      else
        reference_query = relation.select(*column_names).to_sql

        PIIAttributeSupport.pii_columns.each do |table_name, encrypted_attributes|

          # if the table was explicit and doesn't match this one, skip it.
          if reg_match[:table].present? && table_name != reg_match[:table]
            next
          end

          # If this encrypted table isn't in the query at all, skip it
          next if reference_query.exclude?(table_name)

          encrypted_attributes.each do |column_name, config|
            if self.encrypted_column == column_name
              self.model_with_encryption = config[:model_class]
              return true
            end
          end
        end

        self.model_with_encryption = nil
        self.encrypted_column = nil
        false
      end

    rescue NameError
      # pluck is so entrenched, that PIIAttributeSupport.pii_columns can get
      # called before the classes it references are loaded. This is for those startup cases.
      return false
    end

    def decrypter
      e_class = model_with_encryption.dup
      ->(encoded_cipher_text, encoded_iv) do
        if e_class.allow_pii?
          return nil if encoded_cipher_text.blank?

          cipher_text = Base64.decode64(encoded_cipher_text)
          iv = Base64.decode64(encoded_iv)
          Encryption::SoftFailEncryptor.decrypt(value: cipher_text, key: e_class.pii_encryption_key, iv: iv)
        else
          '[REDACTED]'
        end
      end
    end
  end
end
