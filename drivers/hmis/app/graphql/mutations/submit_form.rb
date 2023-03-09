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
      klass = Hmis::Form::Definition::FORM_ROLE_CLASSES[definition.role.to_sym]&.constantize
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

      # TODO! check permissions

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

      # Run both validations
      record_valid = record.valid?
      custom_form_valid = custom_form.valid?

      if record_valid && custom_form_valid
        # We need to call save on the processor directly to get the before_save hook to invoke.
        # If this is removed, the Enrollment won't save.
        custom_form.form_processor.save!
        # Save CustomForm to save the rest of the related records
        custom_form.save!
        # Save the record
        record.save!
        record.touch
        # Update DateUpdated on the Enrollment, if applicable
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
  end
end
