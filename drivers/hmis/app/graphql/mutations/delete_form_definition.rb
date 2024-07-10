###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteFormDefinition < CleanBaseMutation
    include ConfigToolPermissionHelper

    argument :id, ID, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:)
      access_denied! unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition

      ensure_form_role_permission(definition.role)

      raise 'can only delete draft forms' unless definition.draft?

      has_other_versions = definition.all_versions.count > 1

      Hmis::Form::Definition.transaction do
        # If this is the last remaining version of this form, remove all Form Instances.
        definition.instances.each(&:destroy!) unless has_other_versions

        # Soft-delete the Form Definition. This will error if there are any form_processors or external_form_submissions
        # that reference this particular form, which there shouldn't be because it's a Draft.
        definition.destroy!
      end

      {
        form_definition: definition,
      }
    end
  end
end
