###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_submissions'
    belongs_to :definition, class_name: 'Hmis::Form::Definition'

    has_many :custom_data_elements, as: :owner, dependent: :destroy, class_name: 'Hmis::Hud::CustomDataElement'

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
          value_string: value,
          data_source_id: cded.data_source_id,
          data_element_definition_id: cded.id,
          UserID: cded.user_id,
          DateCreated: now,
          DateUpdated: now,
        }
      end
      return if cdes.empty?

      Hmis::Hud::CustomDataElement.import!(cdes, validate: false)
      true
    end
  end
end
