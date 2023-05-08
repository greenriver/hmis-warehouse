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
      errors = HmisErrors::Errors.new

      # Look up form definition
      definition = Hmis::Form::Definition.find_by(id: input.form_definition_id)
      errors.add :form_definition, :required unless definition.present?
      return { errors: errors } if errors.any?

      # Determine record class
      klass = definition.record_class_name&.constantize
      errors.add :form_definition, :invalid unless klass.present?
      return { errors: errors } if errors.any?

      # Find or create record
      hud_user = Hmis::Hud::User.from_user(current_user)
      if input.record_id.present?
        record = klass.viewable_by(current_user).find_by(id: input.record_id)
        if record.is_a?(Hmis::File)
          record&.assign_attributes(updated_by: current_user)
        else
          record&.assign_attributes(user: hud_user)
        end
      else
        record = build_new_record(klass, input)
      end

      errors.add :record, :not_found unless record.present?
      return { errors: errors } if errors.any?

      # Check permission
      allowed = true
      allowed = current_user.permissions_for?(record, *Array(definition.record_editing_permission)) if definition.record_editing_permission.present?
      allowed = definition.allowed_proc.call(record, current_user) if definition.allowed_proc.present?
      errors.add :record, :not_allowed unless allowed
      return { errors: errors } if errors.any?

      # Create CustomForm
      custom_form = Hmis::Form::CustomForm.new(
        owner: record,
        definition: definition,
        values: input.values,
        hud_values: input.hud_values,
      )

      # Validate based on FormDefinition
      form_validations = custom_form.collect_form_validations
      errors.push(*form_validations)

      # Run processor to create/update record(s)
      custom_form.form_processor.run!(owner: record)

      # Run both validations
      is_valid = record.valid?
      is_valid = custom_form.valid? && is_valid

      # Collect validations and warnings from AR Validator classes
      record_validations = custom_form.collect_record_validations(user: current_user)
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
          custom_form.owner = record # Set owner_id to the View id
          custom_form.save!
        else
          custom_form.save!
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
        # These are potentially unfixable errors. Maybe should be server error instead.
        # For now, return them all because they are useful in development.
        errors.add_ar_errors(custom_form.errors&.errors)
        errors.add_ar_errors(record.errors&.errors)
        record = nil
      end

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
      case class_name
      when 'Hmis::Hud::Project'
        {
          organization_id: Hmis::Hud::Organization.viewable_by(current_user).find_by(id: input.organization_id)&.OrganizationID,
        }
      when 'Hmis::Hud::Funder', 'Hmis::Hud::ProjectCoc', 'Hmis::Hud::Inventory'
        {
          project_id: Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)&.ProjectID,
        }
      when 'HmisExternalApis::AcHmis::ReferralRequest'
        {
          project_id: Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)&.id,
        }
      when 'Hmis::Hud::HmisService'
        enrollment = Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: input.enrollment_id)
        {
          enrollment_id: enrollment&.EnrollmentID,
          personal_id: enrollment&.PersonalID,
        }
      when 'Hmis::File'
        {
          client_id: Hmis::Hud::Client.viewable_by(current_user).find_by(id: input.client_id)&.id,
          enrollment_id: Hmis::Hud::Enrollment.viewable_by(current_user).find_by(id: input.enrollment_id)&.id,
        }
      else
        {}
      end
    end

    def build_new_record(klass, input)
      record = klass.new
      record.attributes = related_id_attributes(klass.name, input)
      case record
      when Hmis::File
        record.user = current_user
        record.updated_by = current_user
      when HmisExternalApis::AcHmis::ReferralRequest
        # FIXME
        record.identifier = SecureRandom.uuid
        record.requested_by = current_user
      else
        record.user = current_hud_user
        record.data_source_id = current_hud_user.data_source_id
      end
      record
    end

    def current_hud_user
      Hmis::Hud::User.from_user(current_user)
    end
  end
end
