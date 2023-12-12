###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class UpdateFormRule < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: false

    def resolve(id:, input:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      instance = Hmis::Form::Instance.find_by(id: id)
      raise 'not found' unless instance
      raise 'cannot modify system rule' if instance.system

      instance.project_type = input.project_type
      instance.funder = input.funder
      instance.other_funder = input.other_funder
      instance.data_collected_about = input.data_collected_about
      raise 'invalid' unless instance.valid?

      # instance.entity = input.project

      { form_rule: instance }
    end
  end
end
