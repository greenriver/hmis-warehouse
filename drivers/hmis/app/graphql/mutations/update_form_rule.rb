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

    def resolve(id:, input:)
      instance = Hmis::Form::Instance.find_by(id: id)
      raise 'not found' unless instance
      raise 'cannot modify system rule' if instance.system

      access_denied! unless current_user.can_configure_data_collection_for_role?(instance.definition.role)

      instance.assign_attributes(input.to_attributes)

      if instance.valid?
        instance.save!
        { form_rule: instance }
      else
        errors = HmisErrors::Errors.new
        errors.add_ar_errors(instance.errors)
        { errors: errors }
      end
    end
  end
end
