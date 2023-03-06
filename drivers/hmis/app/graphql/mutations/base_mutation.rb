###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::BaseArgument
    field_class Types::BaseField
    input_object_class Types::BaseInputObject
    object_class Types::BaseObject

    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def current_user
      context[:current_user]
    end

    def hmis_user
      @hmis_user ||= Hmis::Hud::User.from_user(current_user)
    end

    def self.date_string_argument(name, description, **kwargs)
      argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
    end

    # Default CRUD Update functionality
    # If confirm is not specified, treat as confirmed (aka ignore warnings)
    def default_update_record(record:, field_name:, input:, confirmed: true, permissions: nil)
      return { errors: [HmisErrors::Error.new(field_name, :not_found)] } unless record.present?
      return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } if permissions.present? && !current_user.permissions_for?(record, *permissions)

      # Create any custom validation errors
      errors = create_errors(record, input)

      # If user has already confirmed warnings, remove them
      errors = errors.reject(&:warning?) if confirmed

      record.assign_attributes(**input.to_params, user_id: hmis_user.user_id)

      # Add ActiveRecord validation errors to error list
      errors += record.errors.errors unless record.valid?
      return { errors: errors } if errors.any?

      record.save!
      record.touch
      {
        field_name => record,
        errors: [],
      }
    end

    # Override to create custom errors
    def create_errors(_record, _input)
      []
    end

    # Default CRUD Create functionality
    def default_create_record(cls, field_name:, id_field_name:, input:, permissions: nil)
      return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } if permissions.present? && !current_user.permissions?(*permissions)

      record = cls.new(
        **input.to_params,
        id_field_name => Hmis::Hud::Base.generate_uuid,
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
      )

      # check permissions_for here

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
    def default_delete_record(record:, field_name:, permissions: nil)
      return { errors: [HmisErrors::Error.new(field_name, :not_found)] } unless record.present?
      return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } if permissions.present? && !current_user.permissions_for?(record, *permissions)

      record.destroy

      {
        field_name => record,
        errors: [],
      }
    end
  end
end
