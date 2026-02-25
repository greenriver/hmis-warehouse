###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class SubmitForm < BaseMutation
    description 'Submit a form to create/update HUD record(s)'

    argument :input, Types::HmisSchema::FormInput, required: true
    argument :record_lock_version, Integer, required: false

    field :record, Types::HmisSchema::SubmitFormResult, null: true

    def resolve(...)
      Hmis::Hud::Base.transaction do
        _resolve(...)
      end
    end

    protected

    def _resolve(input:, record_lock_version: nil)
      # Look up form definition
      definition = Hmis::Form::Definition.find_by(id: input.form_definition_id)
      raise HmisErrors::ApiError, 'Form Definition not found' unless definition.present?
      raise HmisErrors::ApiError, "FormDefinition #{definition.id} status #{definition.status} is invalid" unless definition.valid_status_for_submit?
      raise HmisErrors::ApiError, "Form Definition #{definition.id} not configured" unless definition.owner_class.present?

      action = input.record_id.present? ? 'edit' : 'create'

      if action == 'edit'
        record = find_record(owner_class: definition.owner_class, record_id: input.record_id)
      else
        record = build_record(owner_class: definition.owner_class, input: input)
      end

      raise "User not authorized to submit form to #{action} #{record.class.name.demodulize}##{record.id || 'new'}" unless authorized_to_submit?(definition: definition, record: record, action: action)

      record.lock_version = record_lock_version if record_lock_version

      # Use existing FormProcessor or build a new one. The FormProcessor handles validating + processing the values into the database,
      # updating any related record(s), and storing references to related records.
      form_processor = record.form_processor || record.build_form_processor
      form_processor.definition = definition # Definition could be different from the last time this record was submitted
      form_processor.values = input.values # Values keyed by link_id are used for validating against the FormDefinition
      form_processor.hud_values = input.hud_values # Fields keyed by field name are saved to the database

      # Validate based on FormDefinition
      errors = HmisErrors::Errors.new
      form_validations = form_processor.collect_form_validations
      errors.push(*form_validations)

      # Run processor to assign attributes to the record(s)
      form_processor.run!(user: current_user)
      # Validate record. Pass 2 contexts: 1 for general form submission, 1 for this specific role.
      is_valid = record.valid?([:form_submission, "#{definition.role.to_s.downcase}_form".to_sym])

      # Collect validations and warnings from AR Validator classes
      record_validations = form_processor.collect_processing_validations(user: current_user)
      errors.push(*record_validations)

      errors.drop_warnings! if input.confirmed
      errors.deduplicate!
      return { errors: errors } if errors.any?

      if is_valid
        # Perform any side effects
        perform_side_effects(record)
        case record
        when Hmis::Hud::Enrollment
          enrollment = record
          # Enrollment form may create or update client, so we need to save that
          enrollment.client.save! if enrollment.client.changed?

          if enrollment.new_record?
            enrollment.save_new_enrollment!
          elsif enrollment.in_progress?
            enrollment.save_in_progress!
          else
            enrollment.save!
          end
        else
          record.save!
          record.touch
        end

        # Save FormProcessor, which may save any related records
        form_processor.save!

        if record.respond_to?(:enrollment)
          # Update DateUpdated on the Enrollment, if record is Enrollment-related
          record.enrollment&.touch
          # Save Enrollment, in case this form changed any fields on Enrollment
          record.enrollment&.save!
        end
      else
        errors.add_ar_errors(record.errors&.errors)
        record = nil
      end

      # resolve service as view model
      if record.is_a?(Hmis::Hud::Service) || record.is_a?(Hmis::Hud::CustomService)
        record = Hmis::Hud::HmisService.find_by(owner: record)
      else
        # Reload to get changes from post_save actions, such as newly created MCI ID.
        record&.reload
      end

      {
        record: record,
        errors: errors,
      }
    end

    private

    # Find 'owner' record being edited with this form submission.
    def find_record(owner_class:, record_id:)
      record = owner_class.viewable_by(current_user).find_by(id: record_id)
      record = record.owner if record.is_a?(Hmis::Hud::HmisService)
      raise "User not authorized to view #{owner_class.name}##{record_id} (record not found)" unless record

      record
    end

    # Build new record for form submission, and associate it with related record passed in input
    def build_record(owner_class:, input:)
      Hmis::Form::SubmitFormRecordInitializer.build(owner_class: owner_class, input: input, user: current_user)
    end

    def authorized_to_submit?(definition:, record:, action:)
      authorizer = Hmis::Form::SubmitFormAuthorizer.new(user: current_user, definition: definition)
      case action
      when 'edit'
        authorizer.authorized_to_edit?(record)
      when 'create'
        authorizer.authorized_to_create?(record)
      else
        raise "Invalid action: #{action}"
      end
    end

    def perform_side_effects(record)
      case record
      when Hmis::Hud::Project
        # If a project was closed, close related Funders and Inventory
        project_closed = record.operating_end_date_was.nil? && record.operating_end_date.present?
        record.close_related_funders_and_inventory! if project_closed
      end
    end
  end
end
