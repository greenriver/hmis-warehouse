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

      errors = HmisErrors::Errors.new
      ::HmisUtil::JsonForms.new.tap do |builder|
        builder.validate_definition(attrs[:definition]) { |err| errors.add(:definition, message: err) }
      end

      return { errors: errors } if errors.present?

      # TODO(#5858) once the publish workflow is in place, we should set status to DRAFT here
      definition = Hmis::Form::Definition.create!(version: 0, status: Hmis::Form::Definition::PUBLISHED, **attrs)

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
