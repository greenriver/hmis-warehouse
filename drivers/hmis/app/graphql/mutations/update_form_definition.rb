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
      access_denied! unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition
      raise 'not allowed to change identifier' if input.identifier.present? && input.identifier != definition.identifier

      # This mutation can be used to update the definition or the title/role, which is why definition is optional.
      definition.assign_attributes(**input.to_attributes) unless input.to_attributes.blank?

      # This definition could be coming from one of two places:
      # 1. The Form Builder (new), which sends input as a json-stringified Typescript object. Its keys are camelCase,
      # and it contains "__typename" keys that need to be removed. The recursively_transform routine fixes this input
      # to match the expected format.
      # 2. The JSON Form Editor (old), which sends keys as a JSON string in the expected format and doesn't need
      # to be transformed, but calling recursively_transform on it is not harmful either.
      definition.definition = recursively_transform(JSON.parse(input.definition)) if input.definition

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

    private

    def recursively_transform(form_element)
      # If it's an array, loop through the array and recursively transform each element
      if form_element.is_a?(Array)
        return form_element.map do |element|
          recursively_transform(element)
        end
      end

      return form_element unless form_element.is_a?(Hash)

      # If it's a hash, first drop unneeded keys and transform them all to snake case
      converted = form_element.
        excluding('__typename'). # drop typescript artifact
        compact. # drop keys with nil values
        transform_keys(&:underscore) # transform keys to snake case

      # Then map through all the sub-elements in the hash and return them
      converted.keys.each do |key|
        converted[key] = recursively_transform(converted[key])
      end

      converted
    end
  end
end
