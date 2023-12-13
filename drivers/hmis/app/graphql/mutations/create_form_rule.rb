###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateFormRule < BaseMutation
    argument :definition_id, ID, required: true
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: false

    def resolve(definition_id:, input:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      definition = Hmis::Form::Definition.find(definition_id)

      instance = Hmis::Form::Instance.new(
        definition_identifier: definition.identifier,
        active: false,
        system: false,
      )
      instance.assign_attributes(input.to_attributes)

      # TODO: validation errors?
      raise 'invalid' unless instance.valid?

      { form_rule: instance }
    end
  end
end
