module GraphqlMutationHelper
  extend ActiveSupport::Concern
  include GraphqlApplicationHelper

  def self.date_string_argument(name, description, **kwargs)
    argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
  end

  # Default CRUD Update functionality
  # If confirm is not specified, treat as confirmed (aka ignore warnings)
  def default_update_record(record:, field_name:, input:, confirmed: true, **auth_args)
    return { errors: [HmisErrors::Error.new(field_name, :not_found)] } unless record.present?
    return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } unless allowed?(record: record, **auth_args)

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
  def default_create_record(cls, field_name:, id_field_name:, input:, **auth_args)
    return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } unless allowed?(**auth_args)

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
  def default_delete_record(record:, field_name:, after_delete: nil, **auth_args)
    raise HmisErrors::ApiError, 'Record not found' unless record.present?
    raise HmisErrors::ApiError, 'Access denied' unless allowed?(record: record, **auth_args)

    record.destroy!
    after_delete&.call

    {
      field_name => record,
      errors: [],
    }
  end
end
