###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  # This mutation is only for creating a new draft of a published form.
  # To create a brand-new form, use CreateFormDefinition
  class CreateNextDraftFormDefinition < CleanBaseMutation
    include ConfigToolPermissionHelper

    argument :identifier, String, required: true

    field :form_identifier, Types::Forms::FormIdentifier, null: true

    def resolve(identifier:)
      access_denied! unless current_user.can_manage_forms?

      definitions = Hmis::Form::Definition.
        exclude_definition_from_select.
        where(identifier: identifier)

      raise 'not found' if definitions.empty?

      existing_drafts = definitions.where(status: Hmis::Form::Definition::DRAFT)

      unless existing_drafts.empty?
        ensure_form_role_permission(existing_drafts.first.role)
        return { form_identifier: existing_drafts.first }
      end

      # Re-fetch the most recent version (could be published or retired) to get the full form definition
      last = Hmis::Form::Definition.find(definitions.max_by(&:version).id)
      ensure_form_role_permission(last.role)

      # Duplicate the last version, incrementing the version number and setting the status to draft
      definition = last.dup
      definition.version = last.version + 1
      definition.status = Hmis::Form::Definition::DRAFT

      definition.save!
      { form_identifier: definition }
    end
  end
end
