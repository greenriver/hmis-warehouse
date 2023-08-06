###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::AcHmis::Importers::Loaders
  class BaseLoader
    def self.perform(...)
      new.perform(...)
    end

    class BaseColumn
      attr_accessor :field
      protected

      def row_value(row, key)
        row[key]&.strip&.presence
      end
    end

    # 1:1 mapping of field to record attribute
    class AttributeColumn < BaseColumn
      attr_accessor :map_to
      def initialize(field, map_to: nil)
        self.field = field
        self.map_to = map_to
      end

      # assign col from row into record
      def assign_value(row:, record:)
        case map_to
        when String, Symbol
          record[map_to] = row_value(row, field)
        when nil
          record[field] = row_value(row, field)
        else
          raise
        end
      end
    end

    # field is stored as CDE on record
    class CommonDataElementColumn < BaseColumn
      attr_accessor :definition, :default_attrs
      def initialize(field, definition:, default_attrs:)
        self.field = field
        self.definition = definition
        self.default_attrs = default_attrs
      end

      # assign col from row into record
      def assign_value(row:, record:)
        value =  row_value(row, 'FundingSource')
        return unless value

        cde_attrs = default_attrs.merge({
          owner_type: model_class.class_name,
          value_string: value,
          data_element_definition_id: definition.id,
          DateCreated: row_value(row, 'DateCreated'),
          DateUpdated: row_value(row, 'DateUpdated'),
        })
        record.custom_data_elements.build(cde_attrs)
      end
    end

    protected

    def attr_col(...)
      AttributeColumn.new(...)
    end

    def cde_col(...)
      CommonDataElementColumn.new(...)
    end

    def system_user
      Hmis::Hud::User.system_user(data_source_id: data_source.id)
    end

    def data_source
      HmisExternalApis::AcHmis.data_source
    end

    def default_attrs
      {
        data_source_id: data_source.id,
        UserID: system_user.UserID
      }
    end
  end
end
