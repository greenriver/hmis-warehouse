###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class FormSubmission < ::HmisExternalApis::HmisExternalApisBase
    self.table_name = 'hmis_external_form_submissions'
    belongs_to :definition, class_name: 'Hmis::Form::Definition'
    belongs_to :enrollment, class_name: 'Hmis::Hud::Enrollment', optional: true
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
        cleaned_values: clean(raw_data),
      }
      submission.save!
      submission
    end

    protected def clean(raw_data)
      raw_data.select { |link_id, _| definition.link_id_item_hash.key?(link_id) }
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
  end
end
