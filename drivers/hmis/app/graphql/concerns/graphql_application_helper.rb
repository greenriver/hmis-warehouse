module GraphqlApplicationHelper
  extend ActiveSupport::Concern

  def current_user
    context[:current_user]
  end

  def hmis_user
    Hmis::Hud::User.from_user(current_user)
  end

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
end
