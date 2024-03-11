module GraphqlMutationHelper
  extend ActiveSupport::Concern

  # This method checks to see if we have the permissions to perform the operation we're doing
  def allowed?(record: nil, permissions: nil, authorize: nil)
    # Default to true because if we didn't provide any permissions to check and no authorize proc, then we assume the action does not require authorization
    allowed = true

    # If a record is present, it will check permissions_for? that record, otherwise it will check for global permissions
    allowed = record ? current_user.permissions_for?(record, *permissions) : current_user.permissions?(*permissions) if permissions.present?
    # If we provided an authorize proc, then use that to check permissions
    allowed = authorize.call(record, current_user) if authorize.present?

    allowed
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
