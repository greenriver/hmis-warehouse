###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::TcHmis::Importers::Loaders
  class CustomDataElementHelper
    attr_accessor :data_source, :system_user, :today

    def initialize(data_source:, system_user:, today:)
      self.data_source = data_source
      self.system_user = system_user
      self.today = today
      @cache = {}
    end

    def cdeds
      Hmis::Hud::CustomDataElementDefinition.where(data_source_id: data_source.id)
    end

    def find_or_create_cded(owner_type:, key:, field_type: nil, repeats: nil, label: nil)
      @cache[[owner_type, key]] ||= _find_or_create_cded(owner_type: owner_type, key: key, field_type: field_type, repeats: repeats, label: label)
    end

    def _find_or_create_cded(owner_type:, key:, field_type: nil, repeats: nil, label: nil)
      cded = cdeds.where(owner_type: owner_type, key: key).first_or_initialize

      field_type = field_type == 'signature' ? 'string' : field_type
      cded.field_type = field_type if field_type
      cded.field_type ||= 'string'

      cded.label = label if label
      cded.label ||= key.to_s.humanize

      cded.repeats = repeats unless repeats.nil?
      cded.repeats = false if cded.repeats.nil?

      cded.user_id ||= system_user.id
      cded.save!
      cded
    end

    def new_cde_record(value:, owner_type:, owner_id:, definition_key:, date_created: today)
      definition = find_or_create_cded(owner_type: owner_type, key: definition_key)
      {
        owner_type: owner_type,
        owner_id: owner_id,
        data_element_definition_id: definition.id,
        DateCreated: date_created,
        DateUpdated: date_created,
        data_source_id: data_source.id,
        UserID: system_user.id,
      }.merge(HmisExternalApis::ExternalForms::FormSubmission.cde_value_fields(definition, value))
    end
  end
end
