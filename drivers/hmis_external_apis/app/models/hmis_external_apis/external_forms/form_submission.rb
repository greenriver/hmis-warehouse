###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_submissions'
    belongs_to :definition, class_name: 'Hmis::Form::Definition'
    include ::Hmis::Hud::Concerns::HasCustomDataElements

    def spam
      # The recaptcha spam score is a float between 0 (likely spam) and 1.0 (likely real)
      # For now we will start with 0.5 as the threshold, maybe we will adjust in future
      spam_score && spam_score < 0.5
    end

    def self.apply_filters(input)
      Hmis::Filter::ExternalFormSubmissionFilter.new(input).filter_scope(self)
    end

    def self.from_raw_data(raw_data, object_key:, last_modified:, form_definition:)
      # there might be a submission already if we processed it but didn't delete it from s3
      submission = where(object_key: object_key).first_or_initialize
      submission.status ||= 'new'

      spam_score = raw_data['spam_score'].presence&.to_i
      submission.attributes = {
        submitted_at: last_modified,
        spam_score: spam_score,
        definition_id: form_definition.id,
        raw_data: raw_data,
      }
      submission.save!
      submission.process_custom_data_elements!(form_definition: form_definition)
      submission
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
    def self.cde_value_fields(definition, value)
      result = {}
      VALUE_FIELDS.map do |field_type, field_name|
        result[field_name] = field_type == definition.field_type ? value : nil
      end
      result
    end

    def process_custom_data_elements!(form_definition:)
      custom_data_elements.delete_all
      cdes = []
      now = Time.current
      form_definition.custom_data_element_definitions.each do |cded|
        value = raw_data[cded.key]
        next if value.blank?

        cdes << {
          owner_type: self.class.sti_name,
          owner_id: id,
          data_source_id: cded.data_source_id,
          data_element_definition_id: cded.id,
          UserID: cded.user_id,
          DateCreated: now,
          DateUpdated: now,
        }.merge(HmisExternalApis::ExternalForms::FormSubmission.cde_value_fields(cded, value))
      end
      return if cdes.empty?

      Hmis::Hud::CustomDataElement.import!(cdes, validate: false)
      true
    end
  end
end
