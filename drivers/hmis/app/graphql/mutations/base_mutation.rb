###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class CustomValidationErrors
    include Enumerable

    extend Forwardable
    def_delegators :@errors, :size, :clear, :blank?, :empty?, :uniq!, :any?, :count
    attr_reader :errors
    alias objects errors

    def initialize
      @errors = []
    end

    def add(attribute, type = :invalid, **options)
      error = CustomValidationError.new(attribute, type, **options)
      @errors.append(error)
      error
    end
  end

  class CustomValidationError
    def initialize(attribute, type = :invalid, message: nil, full_message: nil, severity: :error, **kwargs)
      {
        attribute: attribute,
        type: type,
        message: message,
        full_message: full_message,
        severity: severity,
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
    # If confirm is not specified, treat as confirmed (aka ignore warnings)
    def default_update_record(record:, field_name:, input:, confirmed: true)
      return { field_name => nil, errors: [CustomValidationError.new(field_name, :not_found)] } unless record.present?

      # Create any custom validation errors
      errors = create_errors(record, input)

      # If user has already confirmed warnings, remove them
      errors = errors.filter { |e| e.severity != :warning } if confirmed

      record.assign_attributes(
        **input.to_params,
        user_id: hmis_user.user_id,
        date_updated: DateTime.current,
      )

      # Add ActiveRecord validation errors to error list
      errors += record.errors.errors unless record.valid?

      if errors.empty?
        record.save!
        { field_name => record, errors: [] }
      else
        { field_name => nil, errors: errors }
      end
    end

    # Override to create custom errors
    def create_errors(_record, _input)
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

      errors = create_errors(record, input)

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
        errors << CustomValidationError.new(field_name, :not_found) unless record.present?
      end

      {
        field_name => record,
        errors: errors,
      }
    end
  end
end
