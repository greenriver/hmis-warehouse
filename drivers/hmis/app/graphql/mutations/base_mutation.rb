###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class InputValidationError
    def initialize(message, attribute: nil, **kwargs)
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

    def self.date_string_argument(name, description, **kwargs)
      argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
    end

    # Default CRUD Update functionality
    def default_update_record(record:, field_name:, input:)
      errors = []
      if record.present?
        record.update(
          **input.to_params,
          user_id: hmis_user.user_id,
          date_updated: DateTime.current,
        )
        errors += record.errors.errors unless record.valid?
      else
        errors << InputValidationError.new("#{field_name} record not found", attribute: 'id') unless record.present?
      end

      {
        field_name => record&.valid? ? record : nil,
        errors: errors,
      }
    end

    # Default CRUD Create functionality
    def default_create_record(cls, field_name:, id_field_name:, input:)
      record = cls.new(
        **input.to_params,
        id_field_name => Hmis::Hud::Base.generate_uuid,
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
        date_created: DateTime.current,
      )

      errors = []

      if record.valid?
        record.save!
      else
        errors = record.errors
        record = nil
      end

      {
        field_name => record,
        errors: errors,
      }
    end

    # Default CRUD Delete functionality
    def default_delete_record(record:, field_name:)
      errors = []
      if record.present?
        record.destroy
      else
        errors << InputValidationError.new("#{field_name} record not found", attribute: 'id') unless record.present?
      end

      {
        field_name => record,
        errors: errors,
      }
    end
  end
end
