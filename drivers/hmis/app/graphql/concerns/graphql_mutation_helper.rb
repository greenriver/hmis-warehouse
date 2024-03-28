module GraphqlMutationHelper
  extend ActiveSupport::Concern
  include GraphqlApplicationHelper

  def self.date_string_argument(name, description, **kwargs)
    argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
  end

  # Override to create custom errors
  def create_errors(_record, _input)
    []
  end

  # Default CRUD Create functionality
  def default_create_record(cls, field_name:, id_field_name: nil, input:, exclude_default_fields: false, **auth_args)
    return { errors: [HmisErrors::Error.new(field_name, :not_allowed)] } unless allowed?(**auth_args)

    params = input.to_params

    unless exclude_default_fields
      params = params.merge(
        data_source_id: hmis_user.data_source_id,
        user_id: hmis_user.user_id,
      )
    end

    params[id_field_name] = Hmis::Hud::Base.generate_uuid if id_field_name.present?

    record = cls.new(params)

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
