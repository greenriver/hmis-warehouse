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
      values_to_process = form_values.clone

      # Only if there are Client and/or Enrollment fields in the form definition, initialize an enrollment
      # (which will in turn initialize a Client, inside the form processor).
      if definition.creates_client_or_enrollment? && !enrollment # Not if enrollment already exists - it's already been processed
        household_id = form_values['Enrollment.householdId']
        relationship_to_hoh = form_values['Enrollment.relationshipToHoH']

        # If hh ID is provided, check whether it already exists in anther project. If it does, it's invalid
        if household_id && !Hmis::Hud::Enrollment.where(household_id: household_id).where.not(project: project).exists?
          # If a relationship to HoH was provided, use that
          # TODO - If invalid, the form processor will throw later on
          unless relationship_to_hoh
            # If this hh ID doesn't already exist on any enrollment within this project, then it's new
            hh_id_new = !Hmis::Hud::Enrollment.where(household_id: household_id).where(project: project).exists?

            # Default to 1 SELF if this is a new hh ID and 99 Data Not Collected if not
            relationship_to_hoh = hh_id_new ? 1 : 99
          end
        else
          # If no hh ID was provided, or the provided one was invalid, generate a new one.
          household_id = Hmis::Hud::Enrollment.generate_household_id
          # Reset relationship to 1 SELF if we're generating a new hh ID, regardless of whether it was provided.
          relationship_to_hoh = 1

          # Remove keys from the values to process if they exist, otherwise the form processor will override the values we just set.
          values_to_process.delete('Enrollment.householdId')
          values_to_process.delete('Enrollment.relationshipToHoH')
        end

        build_enrollment(
          project: project,
          data_source: project.data_source,
          entry_date: created_at,
          household_id: household_id,
          relationship_to_hoh: relationship_to_hoh,
          # user is provided by the form processor only when there are enrollment-related fields provided in form_values
          user: Hmis::Hud::User.from_user(current_user),
        )
      end

      form_processor = self.form_processor || build_form_processor(definition: definition)

      form_processor.hud_values = values_to_process
      # We skip the form_processor.collect_form_validations step, because the external form has already been
      # submitted. If it's invalid, there is nothing the user can do about it now.
      # Also skip form_processor.collect_record_validations since e don't want to completely block from processing
      # if the external submission results in invalid values. We should process and allow correction after-the-fact.

      # Run to create CDEs, and client/enrollment if applicable
      form_processor.run!(user: current_user)
    end
  end
end
