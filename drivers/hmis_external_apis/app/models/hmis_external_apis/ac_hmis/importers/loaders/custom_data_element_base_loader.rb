###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# matriculation to new platform
# creates CustomService and CustomDataElements
module HmisExternalApis::AcHmis::Importers::Loaders
  class CustomDataElementBaseLoader < SingleFileLoader
    def perform
      records = build_records
      # destroy existing records and re-import
      clobber_records if clobber

      ar_import(model_class, records)
    end

    def clobber_records
      cde_definitions = cde_definitions_keys.map do |key|
        cde_definition(owner_type: owner_class.name, key: key)
      end
      model_class
        .where(data_source: data_source)
        .where(owner_type: owner_class.name)
        .where(data_element_definition: cde_definitions)
        .destroy_all
    end

    protected

    def new_cde_record(value:, definition_key:)
      return unless value

      definition = cde_definition(owner_type: owner_class.name, key: definition_key)
      {
        owner_type: owner_class.name,
        data_element_definition_id: definition.id,
        DateCreated: today,
        DateUpdated: today,
      }.merge(default_attrs).merge(cde_value_fields(definition, value))
    end

    VALUE_FIELDS = [
      'float',
      'integer',
      'boolean',
      'string',
      'text',
      'date',
      'json',
    ].map { |v| [v, "value_#{v}"] }

    # note, we need to set all fields- bulk insert becomes unhappy if the columns are not uniform
    def cde_value_fields(definition, value)
      result = {}
      VALUE_FIELDS.map do |field_type, field_name|
        result[field_name] = field_type == definition.field_type ? value : nil
      end
      result
    end

    def model_class
      Hmis::Hud::CustomDataElement
    end
  end
end
