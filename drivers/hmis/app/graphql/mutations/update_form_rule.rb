###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateFormRule < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: false

    # note: this mutation is now ONLY used for deleting form rules. should deprecate and replace with a new mutation
    def resolve(id:, input:)
      instance = Hmis::Form::Instance.find_by(id: id)
      raise 'not found' unless instance
      raise 'cannot modify system rule' if instance.system

      access_denied! unless current_user.can_configure_data_collection_for_role?(instance.definition.role)

      instance.assign_attributes(input.to_attributes)

      raise instance.errors.full_messages.join(', ') unless instance.valid? || instance.active == false # allow deactivating an invalid rule

      instance.save!(validate: false)

      { form_rule: instance }
    end
  end
end
