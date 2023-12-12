###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CreateFormRule < BaseMutation
    argument :input, Types::Admin::FormRuleInput, required: true

    field :form_rule, Types::Admin::FormRule, null: false

    def resolve # (input:)
      raise 'not allowed' unless current_user.can_configure_data_collection?

      {}
    end
  end
end
