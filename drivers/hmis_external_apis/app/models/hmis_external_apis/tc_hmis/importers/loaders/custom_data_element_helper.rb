###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomDataElementHelper
    attr_accessor :data_source, :system_user

    def initialize(data_source:, system_user:)
      self.data_source= data_source
      self.system_user= system_user
      @cache = {}
    end

    def cdeds
      Hmis::Hud::CustomDataElementDefinition.where(data_source_id: data_source.id)
    end

    def find_or_create_cded(owner_type:, key:, field_type: :string, repeats: false, label: nil)
      @cache[[owner_type, key]] ||= _find_or_create_cded(owner_type: owner_type, key: key, field_type: field_type, repeats: repeats, label: label)
    end

    def _find_or_create_cded(owner_type:, key:, field_type:, repeats:, label:)
      cded = cdeds.where(owner_type: owner_type, key: key).first_or_initialize
      cded.field_type = field_type
      cded.label = label if label
      cded.label ||= key.humanize
      cded.repeats = repeats
      cded.user_id = system_user.id
      cded.save!
      cded
    end

    def new_cde_record(value:, owner_type:, definition_key:)
      definition = find_or_create_cded(owner_type: owner_type, key: definition_key)
      # Ensure `owner_class.name` is correctly defined or replaced with the correct reference
      {
        owner_type: owner_type, # Assuming owner_class.name was meant to be owner_type
        data_element_definition_id: definition.id,
        DateCreated: today, # Ensure `today` is correctly defined or replaced with the correct reference like `Date.today`
        DateUpdated: today, # Ensure `today` is correctly defined or replaced with the correct reference
      }.merge(default_attrs).merge(cde_value_fields(definition, value)) # Ensure `default_attrs` is correctly defined or implemented
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
  end
end
