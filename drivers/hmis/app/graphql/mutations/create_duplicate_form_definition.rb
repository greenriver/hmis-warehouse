###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateDuplicateFormDefinition < CleanBaseMutation
    argument :identifier, String, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(identifier:)
      definitions = Hmis::Form::Definition.
        exclude_definition_from_select.
        order(version: :desc).
        where(identifier: identifier)

      raise 'not found' if definitions.empty?

      access_denied! unless current_user.can_manage_forms_for_role?(definitions.first.role)

      # Re-fetch the most recent version (could be published or retired) to get the full form definition
      most_recent = Hmis::Form::Definition.find(definitions.first.id)

      # Create a new draft definition, giving it a unique identifier
      definition = Hmis::Form::Definition.new(
        title: 'Copy of ' + most_recent.title, # set title, can be changed later
        identifier: ensure_unique_identifier(most_recent.identifier + '_copy'), # cannot be changed
        status: Hmis::Form::Definition::DRAFT,
        version: 0,
        role: most_recent.role,
        definition: most_recent.definition, # TODO: needs to drop all custom_field_key mappings
      )

      definition.save!

      { form_identifier: definition }
    end

    def ensure_unique_identifier(key)
      return key unless Hmis::Form::Definition.exists?(identifier: key)

      count = 1
      possible_key = key
      while Hmis::Form::Definition.exists?(identifier: key)
        count += 1
        possible_key = "#{key}_#{count}"
        raise if count > 50 # safety
      end
      possible_key
    end
  end
end
