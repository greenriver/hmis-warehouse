###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  # This mutation is only for creating a new draft of a published form.
  # To create a brand-new form, use CreateFormDefinition
  class CreateNextDraftFormDefinition < CleanBaseMutation
    argument :identifier, String, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(identifier:)
      definitions = Hmis::Form::Definition.
        exclude_definition_from_select.
        order(version: :desc).
        where(identifier: identifier)

      raise 'not found' if definitions.empty?

      latest_definition = definitions.first
      access_denied! unless policy_for(latest_definition, policy_type: :form_definition).can_create_draft?

      existing_drafts = definitions.where(status: Hmis::Form::Definition::DRAFT)
      return { form_identifier: existing_drafts.first } unless existing_drafts.empty?

      # Re-fetch the most recent version (could be published or retired) to get the full form definition
      most_recent = Hmis::Form::Definition.find(latest_definition.id)

      # Duplicate the most recent version, incrementing the version number and setting the status to draft
      definition = most_recent.dup
      definition.version = most_recent.version + 1
      definition.status = Hmis::Form::Definition::DRAFT

      definition.save!
      { form_identifier: definition }
    end
  end
end
