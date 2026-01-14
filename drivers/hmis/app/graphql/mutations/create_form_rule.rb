###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class CreateFormRule < BaseMutation
    argument :definition_id, ID, required: true
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: true

    def resolve(definition_id:, input:)
      definition = Hmis::Form::Definition.exclude_definition_from_select.find(definition_id)
      access_denied! unless policy_for(definition, policy_type: :form_definition).can_add_form_rule?

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
