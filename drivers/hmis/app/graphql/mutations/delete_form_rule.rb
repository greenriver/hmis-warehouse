###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class DeleteFormRule < CleanBaseMutation
    argument :id, ID, required: true

    field :form_rule, Types::Admin::FormRule, null: true

    def resolve(id:)
      instance = Hmis::Form::Instance.find_by(id: id)
      raise 'not found' unless instance
      raise 'cannot delete system rule' if instance.system

      access_denied! unless policy_for(instance.definition, policy_type: :form_definition).can_delete_form_rule?

      instance.active = false
      instance.save!(validate: false) # skip validation to support removing an invalid instance

      { form_rule: instance }
    end
  end
end
