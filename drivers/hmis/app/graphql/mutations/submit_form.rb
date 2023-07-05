###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class SubmitForm < BaseMutation
    description 'Submit a form to create/update HUD record(s)'

    argument :input, Types::HmisSchema::FormInput, required: true

    field :record, Types::HmisSchema::SubmitFormResult, null: true

    def resolve(input:)
      # Look up form definition
      definition = Hmis::Form::Definition.find_by(id: input.form_definition_id)
      raise HmisErrors::ApiError, 'Form Definition not found' unless definition.present?

      # Determine record class
      klass = definition.record_class_name&.constantize
      raise HmisErrors::ApiError, 'Form Definition not configured' unless klass.present?

      # Find or create record
      if input.record_id.present?
        record = klass.viewable_by(current_user).find_by(id: input.record_id)
      else
        record = klass.new(
          **related_id_attributes(klass.name, input),
          data_source_id: current_user.hmis_data_source_id, # Not all records actually have this, but we need it to check permissions for some of them
        )
      end
      raise HmisErrors::ApiError, 'Record not found' unless record.present?

      # Check permission
      allowed = nil
      if definition.allowed_proc.present?
        allowed = definition.allowed_proc.call(record, current_user)
      elsif definition.record_editing_permission.present?
        allowed = current_user.permissions_for?(record, *Array(definition.record_editing_permission))
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
      form_validations = definition.validate_form_values(input.values)
      errors.push(*form_validations)

      # Run processor to create/update record(s)
      form_processor.run!(owner: record, user: current_user)

      # Validate record (TODO what about related records?)
      is_valid = record.valid?

      # Collect validations and warnings from AR Validator classes
      record_validations = form_processor.collect_record_validations(user: current_user)
      errors.push(*record_validations)

      errors.drop_warnings! if input.confirmed
      errors.deduplicate!
      return { errors: errors } if errors.any?

      if is_valid
        # Perform any side effects
        perform_side_effects(record)

        if record.is_a? Hmis::Hud::HmisService
          record.owner.save! # Save the actual service record
          record = Hmis::Hud::HmisService.find_by(owner: record.owner) # Refresh from View
        elsif record.is_a? HmisExternalApis::AcHmis::ReferralRequest
          HmisExternalApis::AcHmis::CreateReferralRequestJob.perform_now(record)
        elsif record.is_a? Hmis::Hud::Enrollment
          record.save_in_progress
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
      if record.is_a?(Hmis::Hud::Client)
        if record.new_record?
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay.run!
        else
          GrdaWarehouse::Tasks::IdentifyDuplicates.new.delay.match_existing!
        end
      end

      return unless record.is_a? Hmis::Hud::Project
      return unless record.operating_end_date_was.nil? && record.operating_end_date.present?

      record.close_related_funders_and_inventory!
    end

    private def related_id_attributes(class_name, input)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id) if input.project_id.present?
      client = Hmis::Hud::Client.viewable_by(current_user).find_by(id: input.client_id) if input.client_id.present?
      enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: input.enrollment_id) if input.enrollment_id.present?

      case class_name
      when 'Hmis::Hud::Project'
        {
          organization_id: Hmis::Hud::Organization.viewable_by(current_user).find_by(id: input.organization_id)&.OrganizationID,
        }
      when 'Hmis::Hud::Funder', 'Hmis::Hud::ProjectCoc', 'Hmis::Hud::Inventory'
        {
          project_id: project&.ProjectID,
        }
      when 'HmisExternalApis::AcHmis::ReferralRequest'
        {
          project_id: project&.id,
        }
      when 'Hmis::Hud::HmisService'
        custom_service_type = Hmis::Hud::CustomServiceType.find_by(id: input.service_type_id)
        {
          enrollment_id: enrollment&.EnrollmentID,
          personal_id: enrollment&.PersonalID,
          custom_service_type_id: custom_service_type&.id,
        }
      when 'Hmis::File'
        {
          client_id: client&.id,
          enrollment_id: enrollment&.id,
        }
      when 'Hmis::Hud::Enrollment'
        {
          project_id: project&.ProjectID,
          personal_id: client&.personal_id,
        }
      else
        {}
      end
    end
  end
end
