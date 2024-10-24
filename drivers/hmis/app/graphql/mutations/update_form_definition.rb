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
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      # The UI currently does allow changing the form role, so we make this permission check twice:
      # - to confirm the user has permission to manage the role from the input (in case it's changing)
      # - to confirm the user has permission to manage forms for the original role (from the definition)
      access_denied! if input.role && !current_user.can_manage_forms_for_role?(input.role)
      access_denied! unless current_user.can_manage_forms_for_role?(definition.role)

      raise 'only allowed to modify draft forms' unless definition.draft?
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

      # Return user-facing validation errors for the form content
      validation_errors = definition.validate_json_form
      return { errors: validation_errors } if validation_errors.any?

      # Raise if the definition is not valid (invalid role/status/identifier; not expected)
      raise "Definition invalid: #{definition.errors.full_messages}" unless definition.valid?

      # Manually save a PaperTrail version, so we know who made the change. Because we `skip` the definition
      # field, a PaperTrail record will not automatically get created if only the definition changed.
      definition.paper_trail.save_with_version
      { form_definition: definition }
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
        excluding('__typename', ''). # drop typescript artifacts and empty keys
        compact. # drop keys with nil values
        # drop empty arrays and empty strings
        delete_if { |_key, value| (value.is_a?(Array) || value.is_a?(String)) && value.empty? }.
        transform_keys(&:underscore) # transform keys to snake case

      # Then map through all the sub-elements in the hash and return them
      converted.keys.each do |key|
        converted[key] = recursively_transform(converted[key])
      end

      converted
    end
  end
end
