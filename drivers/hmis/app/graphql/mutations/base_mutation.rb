###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class InputValidationError
    def initialize(message, attribute:, **kwargs)
      {
        message: message,
        attribute: attribute,
        **kwargs,
      }.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end

  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    def current_user
      context[:current_user]
    end

    def hmis_user
      Hmis::Hud::User.where(user_email: current_user.email, data_source_id: current_user.hmis_data_source_id).first_or_create do |u|
        u.user_id = current_user.id
        u.user_first_name = current_user.first_name
        u.user_last_name = current_user.last_name
        u.data_source_id = current_user.hmis_data_source_id
      end
    end

    private

    def _create_validation_error(message:, attribute:, **kwargs)
      InputValidationError.new(message: message, attribute: attribute, **kwargs)
    end
  end
end
