###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteFormDefinition < CleanBaseMutation
    argument :id, ID, required: true

    field :form_definition, Types::Forms::FormDefinition, null: true

    def resolve(id:)
      raise 'not allowed' unless current_user.can_manage_forms?

      definition = Hmis::Form::Definition.find_by(id: id)
      raise 'not found' unless definition
      raise "can't delete definition with active rules" if definition.instances.active.exists?

      definition.destroy!

      {
        form_definition: definition,
        errors: [],
      }
    end
  end
end
