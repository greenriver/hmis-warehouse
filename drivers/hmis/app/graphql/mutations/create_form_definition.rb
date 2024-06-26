###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateFormDefinition < CleanBaseMutation
    argument :input, Types::Admin::FormDefinitionInput, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(input:)
      raise 'not allowed' unless current_user.can_manage_forms?

      attrs = input.to_attributes
      attrs[:definition] = attrs[:definition] || { item: [{ link_id: 'name', type: 'STRING' }] }

      definition = Hmis::Form::Definition.new(
        version: 0,
        status: Hmis::Form::Definition::DRAFT,
        **attrs,
      )

      validation_errors = definition.validate_json
      return { errors: validation_errors } if validation_errors.any?

      definition.save!
      { form_definition: definition }
    end
  end
end
