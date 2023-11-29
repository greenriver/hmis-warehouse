module GraphqlMutationHelper
  extend ActiveSupport::Concern
  include GraphqlApplicationHelper

  def self.date_string_argument(name, description, **kwargs)
    argument name, String, description, validates: { format: { with: /\d{4}-\d{2}-\d{2}/ } }, **kwargs
  end

  # Assign meta data info for paper trail versions created with block. We "request-level" attributes rather than using
  # `has_paper_trail(meta: {})` as that requires additional lookup queries during save
  def with_paper_trail_meta(client_id: nil, enrollment_id: nil, project_id: nil, &block)
    current = PaperTrail.request.controller_info || {}
    controller_info = current.merge({
      client_id: client_id,
      enrollment_id: enrollment_id,
      project_id: project_id,
    }.compact_blank)

    PaperTrail.request(controller_info: controller_info, &block)
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
      with_paper_trail_meta(**record.paper_trail_info_for_mutation) do
        record.save!
      end
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

    with_paper_trail_meta(**record.paper_trail_info_for_mutation) do
      record.destroy!
      after_delete&.call
    end

    {
      field_name => record,
      errors: [],
    }
  end
end
