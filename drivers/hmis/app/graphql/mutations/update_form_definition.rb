###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class UpdateFormDefinition < CleanBaseMutation
    argument :id, ID, required: true
    argument :input, Types::Admin::FormDefinitionInput, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:, input:)
      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      access_denied! unless policy_for(definition, policy_type: :form_definition).can_edit_draft?

      raise 'only allowed to modify draft forms' unless definition.draft?
      raise 'not allowed to change identifier' if input.identifier.present? && input.identifier != definition.identifier
      raise 'not allowed to change role' if input.role.present? && input.role != definition.role

      # The External Form Key is the form's public URL path, so once a version of the form has been published
      # the key is locked. The model validates the key's format.
      new_key = Hmis::Form::Definition.normalize_value_for(:external_form_object_key, input.external_form_object_key)
      if input.to_h.key?(:external_form_object_key) && definition.external_form_object_key.present? && new_key != definition.external_form_object_key
        previously_published = Hmis::Form::Definition.where(identifier: definition.identifier, data_source_id: definition.data_source_id).published_or_retired.exists?
        raise 'not allowed to change external form object key after the form has been published' if previously_published
      end

      # This mutation can be used to update the definition or the title, which is why definition is optional.
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

      # Return model validation errors, such as an invalid or already-taken external_form_object_key
      unless definition.valid?
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(definition.errors.errors)
        return { errors: errors }
      end

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
