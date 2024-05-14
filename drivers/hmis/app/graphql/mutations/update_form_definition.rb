###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateFormDefinition < CleanBaseMutation
    argument :id, ID, required: true
    argument :input, Types::Admin::FormDefinitionInput, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:, input:)
      raise 'not allowed' unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition
      raise 'not allowed to change identifier' if input.identifier.present? && input.identifier != definition.identifier

      definition.assign_attributes(**input.to_attributes)

      errors = HmisErrors::Errors.new
      ::HmisUtil::JsonForms.new.tap do |builder|
        builder.validate_definition(definition.definition) { |err| errors.add(:definition, message: err) }
      end

      return { errors: errors } if errors.present?

      if definition.valid?
        definition.save!
        { form_definition: definition }
      else
        errors.add_ar_errors(definition.errors)
        { errors: errors }
      end
    end
  end
end
