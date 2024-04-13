###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

      # Determine record class
      klass = definition.owner_class
      raise HmisErrors::ApiError, 'Form Definition not configured' unless klass.present?

      # Find or create record
      if input.record_id.present?
        record = klass.viewable_by(current_user).find_by(id: input.record_id)
        record.lock_version = record_lock_version if record_lock_version
        entity_for_permissions = record # If we're editing an existing record, always use that as the permission base
      else
        entity_for_permissions, record = permission_base_and_record(klass, input, current_user.hmis_data_source_id)
      end

      raise HmisErrors::ApiError, 'Record not found' unless record.present?

      # Check permission
      allowed = nil
      perms_to_check = definition.record_editing_permissions
      if definition.allowed_proc.present?
        allowed = definition.allowed_proc.call(entity_for_permissions, current_user)
      elsif perms_to_check.any? && entity_for_permissions.present?
        allowed = current_user.permissions_for?(entity_for_permissions, *perms_to_check)
      elsif perms_to_check.any?
        # if there was no entity specified, perms are checked globally
        allowed = current_user.permissions?(*perms_to_check)
      else
        # allow if no permission check defined
        allowed = true
      end
      raise HmisErrors::ApiError, 'Access Denied' unless allowed

      # Build FormProcessor
      # It wont be persisted, but it handles validation and updating the relevant record(s)
      form_processor = Hmis::Form::FormProcessor.new(
        definition: definition,
        values: input.values,
        hud_values: input.hud_values,
      )

      # Validate based on FormDefinition
      errors = HmisErrors::Errors.new
      form_validations = form_processor.collect_form_validations
      errors.push(*form_validations)

      # Run processor to assign attributes to the record(s)
      form_processor.run!(owner: record, user: current_user)

      # Validate record. Pass 2 contexts: 1 for general form submission, 1 for this specific role.
      is_valid = record.valid?([:form_submission, "#{definition.role.to_s.downcase}_form".to_sym])

      # Collect validations and warnings from AR Validator classes
      record_validations = form_processor.collect_record_validations(user: current_user)
      errors.push(*record_validations)

      errors.drop_warnings! if input.confirmed
      errors.deduplicate!
      return { errors: errors } if errors.any?

      if is_valid
        # Perform any side effects
        perform_side_effects(record)

        case record
        when Hmis::Hud::HmisService
          record.owner.save! # Save the actual service record
          record = Hmis::Hud::HmisService.find_by(owner: record.owner) # Refresh from View
        when HmisExternalApis::AcHmis::ReferralRequest
          HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(record)
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

        if record.respond_to?(:enrollment)
          # Update DateUpdated on the Enrollment, if record is Enrollment-related
          record.enrollment&.touch
          # Update Enrollment itself in case this form changed any fields on Enrollment
          record.enrollment&.save!
        end
      else
        errors.add_ar_errors(record.errors&.errors)
        record = nil
      end

      # Reload to get changes from post_save actions, such as newly created MCI ID.
      record&.reload

      {
        record: record,
        errors: errors,
      }
    end

    private def perform_side_effects(record)
      case record
      when Hmis::Hud::Project
        # If a project was closed, close related Funders and Inventory
        project_closed = record.operating_end_date_was.nil? && record.operating_end_date.present?
        record.close_related_funders_and_inventory! if project_closed
      end
    end

    # For NEW RECORD CREATION ONLY, get the permission base that should be used to check permissions,
    # as well the initial record, initialized with any related record attributes.
    private def permission_base_and_record(klass, input, data_source_id)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id) if input.project_id.present?
      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: input.client_id) if input.client_id.present?
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: input.enrollment_id) if input.enrollment_id.present?
      organization = Hmis::Hud::Organization.viewable_by(current_user).find_by(id: input.organization_id) if input.organization_id.present?
      custom_service_type = Hmis::Hud::CustomServiceType.find_by(id: input.service_type_id) if input.service_type_id.present?

      ds = { data_source_id: data_source_id }
      case klass.name
      when 'Hmis::Hud::Client'
        # 'nil' because there is no permission base for client creation; the permission is checked globally.
        [nil, klass.new(ds)]
      when 'Hmis::Hud::Organization'
        # 'nil' because there is no permission base for organization creation; the permission is checked globally.
        [nil, klass.new(ds)]
      when 'Hmis::Hud::Project'
        [organization, klass.new({ organization_id: organization&.organization_id, **ds })]
      when 'Hmis::Hud::Funder', 'Hmis::Hud::ProjectCoc', 'Hmis::Hud::Inventory', 'Hmis::Hud::CeParticipation', 'Hmis::Hud::HmisParticipation'
        [project, klass.new({ project_id: project&.project_id, **ds })]
      when 'Hmis::Hud::Enrollment'
        [project, klass.new({ actual_project_id: project&.id, personal_id: client&.personal_id, **ds })]
      when 'Hmis::Hud::CurrentLivingSituation'
        [enrollment, klass.new({ personal_id: enrollment&.personal_id, enrollment_id: enrollment&.enrollment_id, **ds })]
      when 'Hmis::Hud::HmisService'
        [
          enrollment, klass.new({
                                  enrollment_id: enrollment&.EnrollmentID,
                                  personal_id: enrollment&.PersonalID,
                                  custom_service_type_id: custom_service_type&.id,
                                  **ds,
                                })
        ]
      when 'HmisExternalApis::AcHmis::ReferralRequest'
        [project, klass.new({ project_id: project&.id })]
      when 'Hmis::File'
        [client, klass.new({ client_id: client&.id, enrollment_id: enrollment&.id })]
      when 'Hmis::Hud::Assessment', 'Hmis::Hud::CustomCaseNote', 'Hmis::Hud::Event'
        [enrollment, klass.new({ personal_id: enrollment&.personal_id, enrollment_id: enrollment&.enrollment_id, **ds })]
      else
        raise "No permission base specified for creating a new record of type #{klass.name}"
      end
    end
  end
end
