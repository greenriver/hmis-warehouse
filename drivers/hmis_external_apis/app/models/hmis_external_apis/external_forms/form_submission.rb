###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_submissions'
    belongs_to :definition, class_name: 'Hmis::Form::Definition'
    # Enrollment that was generated as a result of processing this form submission. Only applicable for certain external forms, like the PIT.
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
    has_one :form_processor, class_name: 'Hmis::Form::FormProcessor', as: :owner

    include ::Hmis::Hud::Concerns::FormSubmittable

    # The recaptcha spam score is a float between 0 (likely spam) and 1.0 (likely real)
    # For now we will start with 0.5 as the threshold, maybe we will adjust in future
    SPAM_THRESHOLD = 0.5
    scope :not_spam, -> { where(spam_score: SPAM_THRESHOLD...).or(where(spam_score: nil)) }
    scope :spam, -> { where(spam_score: ..SPAM_THRESHOLD) }

    def spam
      spam_score && spam_score < SPAM_THRESHOLD
    end

    def self.apply_filters(input)
      Hmis::Filter::ExternalFormSubmissionFilter.new(input).filter_scope(self)
    end

    def self.from_raw_data(raw_data, object_key:, last_modified:, form_definition:, spam_score: nil)
      # there might be a submission already if we processed it but didn't delete it from s3
      submission = where(object_key: object_key).first_or_initialize
      submission.status ||= 'new'
      submission.spam_score ||= spam_score

      submission.attributes = {
        submitted_at: last_modified,
        definition_id: form_definition.id,
        raw_data: raw_data,
      }
      submission.save!
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

    # keys that are added to raw_values upon submission, but are not part of the form values
    EXTRANEOUS_KEYS = ['captcha_score', 'form_definition_id', 'form_content_digest'].freeze

    def form_values
      raw_data.reject { |key, _| EXTRANEOUS_KEYS.include?(key) }
    end

    def run_form_processor(project, current_user)
      # Only if there are Client and/or Enrollment fields in the form definition, initialize an enrollment
      # (which will in turn initialize a Client, inside the form processor).
      if definition.creates_client_or_enrollment?
        build_enrollment(project: project, data_source: project.data_source, entry_date: created_at)
        # Assume that required values on Client and Enrollment (e.g. relationship to HoH) are present
        # and correctly mapped in raw_values. The form processor record validator will fail otherwise.
      end

      form_processor = build_form_processor(definition: definition)

      form_processor.hud_values = form_values
      # We skip the form_processor.collect_form_validations step, because the external form has already been
      # submitted. If it's invalid, there is nothing the user can do about it now.
      # Also skip form_processor.collect_record_validations since e don't want to completely block from processing
      # if the external submission results in invalid values. We should process and allow correction after-the-fact.

      # Run to create CDEs, and client/enrollment if applicable
      form_processor.run!(user: current_user)
    end
  end
end
