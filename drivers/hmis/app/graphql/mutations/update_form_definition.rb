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

      definition.assign_attributes(**input.to_attributes)

      # This definition could be coming from one of two places:
      # 1. The Form Builder (new), which sends input as a json-stringified Typescript object. Its keys are camelCase,
      # and it contains "__typename" keys that need to be removed. The recursively_transform routine fixes this input
      # to match the expected format.
      # 2. The JSON Form Editor (old), which sends keys as a JSON string in the expected format and doesn't need
      # to be transformed, but calling recursively_transform on it is not harmful either.
      definition.definition = recursively_transform(JSON.parse(input.definition))

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
      # First drop unneeded keys and transform them all to snake case
      converted = transform_hash(form_element)

      # Then map through all the elements in the result object
      converted.keys.each do |key|
        if converted[key].is_a?(Array)
          # If it's an array, recursively transform each element in the array
          converted[key] = converted[key].map do |element|
            recursively_transform(element)
          end
        elsif converted[key].is_a?(Hash)
          # If it's a hash, recursively transform the hash, so that all its nested elements also get transformed
          converted[key] = recursively_transform(converted[key])
        end
        # If it's neither an array nor a hash, assume it has been properly handled by the transform_hash call above. No recursion needed
      end

      converted
    end

    def transform_hash(input)
      input.excluding('__typename').
        compact. # drop keys with nil values
        transform_keys(&:underscore) # transform keys to snake case
    end
  end
end
