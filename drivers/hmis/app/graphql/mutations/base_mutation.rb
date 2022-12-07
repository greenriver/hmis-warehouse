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
        full_message: message,
        type: :invalid,
        **kwargs,
      }.each do |key, value|
        define_singleton_method(key) { value }
      end
    end
  end

  class InputConfirmationWarning
    def initialize(message, attribute: nil, **kwargs)
      {
        message: message,
        attribute: attribute,
        full_message: message,
        type: :confirm_warning,
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
      Hmis::Hud::User.from_user(current_user)
    end

    def self.date_string_argument(name, description, **kwargs)
      argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
    end

    # Default CRUD Update functionality
    def default_update_record(record:, field_name:, input:, confirmed: nil)
      return { field_name => nil, errors: [InputValidationError.new("#{field_name.to_s.humanize} record not found", attribute: 'id')] } unless record.present?

      # If confirm is not specified, treat as confirmed (aka ignore warnings)
      confirmed = true if confirmed.nil?

      errors = []
      # Add custom warnings to error list
      errors += create_warnings(record, input) unless confirmed

      record.assign_attributes(
        **input.to_params,
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
      )

      # Add validation errors to error list
      errors += record.errors.errors unless record.valid?

      if errors.empty?
        record.save!
        { field_name => record, errors: [] }
      else
        { field_name => nil, errors: errors }
      end
    end

    # Override to create custom warnings
    def create_warnings(_record, _input)
      []
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
        errors << InputValidationError.new("#{field_name.to_s.humanize} record not found", attribute: 'id') unless record.present?
      end

      {
        field_name => record,
        errors: errors,
      }
    end
  end
end
