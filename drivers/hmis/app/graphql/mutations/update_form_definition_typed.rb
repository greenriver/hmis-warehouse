#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

module Mutations
  # Similar to UpdateFormDefinition, but accepts a typed definition instead of a JSON object.
  # This allows the frontend to be completely shielded from creating and manipulating JSON objects with snake_case keys.
  class UpdateFormDefinitionTyped < CleanBaseMutation
    argument :id, ID, required: true
    argument :definition, 'Types::Admin::FormDefinitionTypedInput', required: false
    # TODO(#6005) - add role and title as inputs
    # argument :role, Types::Forms::Enums::FormRole, required: false
    # argument :title, String, required: false

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:, definition:)
      raise 'not allowed' unless current_user.can_manage_forms?

      form_definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless form_definition

      form_definition.definition = definition

      errors = HmisErrors::Errors.new
      ::HmisUtil::JsonForms.new.tap do |builder|
        builder.validate_definition(form_definition.definition) { |err| errors.add(:definition, message: err) }
      end

      return { errors: errors.errors } if errors.any?

      if form_definition.valid?
        form_definition.save!
        { form_definition: form_definition }
      else
        errors.add_ar_errors(form_definition.errors)
        { errors: errors }
      end
    end
  end
end
