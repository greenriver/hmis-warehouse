###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateDuplicateFormDefinition < CleanBaseMutation
    argument :identifier, String, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(identifier:)
      # Choose the most recent Published or Retired definition to duplicate
      definition_to_duplicate = Hmis::Form::Definition.
        where(identifier: identifier).
        published_or_retired.
        order(version: :desc).first

      raise 'not found' unless definition_to_duplicate

      access_denied! unless current_user.can_manage_forms_for_role?(definition_to_duplicate.role)

      # Drop all custom_field_key mappings on definition structure
      cleaned_definition_json = remove_custom_field_mappings(definition_to_duplicate.dup)

      # Create a new draft definition, giving it a unique identifier
      definition = Hmis::Form::Definition.new(
        title: 'Copy of ' + definition_to_duplicate.title, # set title, can be changed later
        identifier: ensure_unique_identifier(definition_to_duplicate.identifier + '_copy'), # cannot be changed
        status: Hmis::Form::Definition::DRAFT,
        version: 0,
        role: definition_to_duplicate.role,
        definition: cleaned_definition_json,
      )

      definition.save!

      { form_identifier: definition }
    end

    # Remove any cutom fields mappings `{mapping: {custom_field_key: '...'}}` when duplicating.
    # When this form is published, new custom field keys will be re-generated for these questions.
    # Mappings for standard HUD fields are retained.
    def remove_custom_field_mappings(definition)
      definition.walk_definition_nodes do |item|
        next unless item.dig('mapping', 'custom_field_key')

        item.delete('mapping')
      end
      definition.definition
    end

    def ensure_unique_identifier(key)
      return key unless Hmis::Form::Definition.exists?(identifier: key)

      count = 1
      possible_key = key
      while Hmis::Form::Definition.exists?(identifier: possible_key)
        count += 1
        possible_key = "#{key}_#{count}"
        raise 'count exceeded' if count > 50 # safety
      end
      possible_key
    end
  end
end
