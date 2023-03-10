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
        record&.assign_attributes(user: hud_user)
      else
        record = klass.new(user: hud_user, data_source_id: hud_user.data_source_id)
        input.apply_related_ids(record)
      end

      errors.add :record, :not_found unless record.present?
      return { errors: errors } if errors.any?

      # Check permission
      errors.add :record, :not_allowed unless current_user.permissions_for?(record, definition.record_editing_permission)
      return { errors: errors } if errors.any?

      # Create CustomForm
      custom_form = Hmis::Form::CustomForm.new(
        owner: record,
        definition: definition,
        values: input.values,
        hud_values: input.hud_values,
      )

      # Validate based on FormDefinition
      validation_errors = custom_form.validate_form(ignore_warnings: input.confirmed)
      errors.push(*validation_errors)
      return { errors: errors } if errors.any?

      # Run processor to create/update record(s)
      custom_form.form_processor.run!

      # Run custom validator for any warnings/errors (like closing a Project)
      validator = klass.validators.find { |v| v.respond_to?(:hmis_validate) }
      if validator.present?
        validation_errors = validator.hmis_validate(record, ignore_warnings: input.confirmed)
        errors.push(*validation_errors)
      end
      return { errors: errors } if errors.any?

      # Run both validations
      record_valid = record.valid?
      custom_form_valid = custom_form.valid?

      if record_valid && custom_form_valid
        # Perform any side effects
        perform_side_effects(record)
        # Save CustomForm to save any related records (if any)
        custom_form.save!
        # Save the record
        record.save!
        record.touch
        # Update DateUpdated on the Enrollment, if record is Enrollment-related
        record.enrollment.touch if record.respond_to?(:enrollment)
      else
        # These are potentially unfixable errors, so maybe we should throw a server error instead.
        # Leaving them visible to the user for now, while we QA the feature.
        errors.push(*custom_form&.errors&.errors)
        errors.push(*record.errors&.errors)
        record = nil
      end

      {
        record: record,
        errors: errors,
      }
    end

    private def perform_side_effects(record)
      return unless record.is_a? Hmis::Hud::Project
      return unless record.operating_end_date_was.nil? && record.operating_end_date.present?

      record.funders.where(end_date: nil).update_all(end_date: record.operating_end_date)
      record.inventories.where(inventory_end_date: nil).update_all(inventory_end_date: record.operating_end_date)
    end
  end
end
