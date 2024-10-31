###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateFormRule < BaseMutation
    argument :definition_id, ID, required: true
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: true

    def resolve(definition_id:, input:)
      definition = Hmis::Form::Definition.exclude_definition_from_select.find(definition_id)
      access_denied! unless current_user.can_configure_data_collection_for_role?(definition.role)

      instance = Hmis::Form::Instance.new(definition_identifier: definition.identifier)
      instance.assign_attributes(input.to_attributes)

      if instance.valid?
        instance.save!
        { form_rule: instance }
      else
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(instance.errors.errors)
        { errors: errors }
      end
    end
  end
end
