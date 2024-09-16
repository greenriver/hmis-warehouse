###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class DeleteFormRule < CleanBaseMutation
    argument :id, ID, required: true

    field :form_rule, Types::Admin::FormRule, null: true

    def resolve(id:)
      instance = Hmis::Form::Instance.find_by(id: id)
      raise 'not found' unless instance
      raise 'cannot delete system rule' if instance.system

      access_denied! unless current_user.can_configure_data_collection_for_role?(instance.definition.role)

      instance.destroy!

      { form_rule: instance }
    end
  end
end
