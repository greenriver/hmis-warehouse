###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateFormDefinition < CleanBaseMutation
    argument :id, ID, required: true
    argument :input, String, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:, input:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      definition_json = JSON.parse(input)

      errors = HmisErrors::Errors.new
      ::HmisUtil::JsonForms.new.tap do |builder|
        builder.validate_definition(definition_json, on_error: ->(err) { errors.add(:definition, message: err.message) })
      end

      return { errors: errors } if errors.present?

      definition.assign_attributes(definition: JSON.parse(input))

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
