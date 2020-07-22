###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CustomBulkInsert
  extend ActiveSupport::Concern

  def insert_batch(klass, columns, values, transaction: true, batch_size: 200)
    return if values.empty?

    if transaction
      klass.transaction do
        _process klass, columns, values, batch_size: batch_size
      end
    else
      _process klass, columns, values, batch_size: batch_size
    end
  end

  private

  def _process(klass, columns, values, batch_size: 200)
    needs_encryption = klass.included_modules.include?(PIIAttributeSupport) && Encryption::Util.encryption_enabled?

    if needs_encryption
      values = _transform_values(klass, columns, values)
      columns = _transform_columns(klass, columns)
    end

    klass.import columns, values, batch_size: batch_size
  end

  def _transform_values(klass, columns, values)
    @saved_allow_pii = klass.allow_pii?
    klass.allow_pii!

    transformers =
      columns.map(&:to_sym).map do |column|
        if column.in?(klass.encrypted_attributes.keys)
          ->(val) do
            # TODO: move to pii concern once working
            iv = SecureRandom.bytes(12)
            cipher_text = Encryption::SoftFailEncryptor.encrypt(value: val, key: klass.pii_encryption_key, iv: iv)

            [
              Base64.encode64(cipher_text),
              Base64.encode64(iv),
            ]
          end
        else
          ->(val) { [val] }
        end
      end

    values.map do |record|
      result = []
      transformers.each.with_index do |func, i|
        result += func.call(record[i])
      end
      result
    end
  ensure
    if @saved_allow_pii
      klass.allow_pii!
    else
      klass.deny_pii!
    end
  end

  def _transform_columns(klass, columns)
    columns.map(&:to_sym).flat_map do |column|
      if column.in?(klass.encrypted_attributes.keys)
        [
          klass.encrypted_attributes.dig(column, :attribute),
          "#{encrypted_attributes.dig(column, :attribute)}_iv".to_sym,
        ]
      else
        [column]
      end
    end
  end
end
