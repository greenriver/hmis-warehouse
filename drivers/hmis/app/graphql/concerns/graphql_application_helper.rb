module GraphqlApplicationHelper
  extend ActiveSupport::Concern

  def current_user
    context[:current_user]
  end

  def true_user
    context[:true_user]
  end

  def hmis_user
    Hmis::Hud::User.from_user(current_user)
  end

  def access_denied!(message = 'access denied')
    raise message
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

  # Does the current user have the given permission on entity?
  #
  # @param permission [Symbol] :can_do_foo
  # @param entity [#record] Client, project, etc
  def current_permission?(permission:, entity:)
    GraphqlPermissionChecker.current_permission_for_context?(context, permission: permission, entity: entity)
  end

  # Use data loader to load an ActiveRecord association.
  # Note: 'scope' is intended for ordering or to modify the default
  # association in a way that is constant with respect to the resolver,
  # for example `scope: FooBar.order(:name)`. It is NOT used to filter down results.
  def load_ar_association(object, association, scope: nil)
    raise "object must be an ApplicationRecord, got #{object.class.name}" unless object.is_a?(ApplicationRecord)

    dataloader.with(Sources::ActiveRecordAssociation, association, scope).load(object)
  end

  def load_ar_scope(scope:, id:)
    dataloader.with(Sources::ActiveRecordScope, scope).load(id)
  end

  # Helper to resolve the active enrollment for this client at the specified project on the specified date.
  # Include WIP enrollments. If there are multiple enrollments, choose the one with the older entry date.
  #
  # This is in this module because its shared between query and mutation code.
  def load_open_enrollment_for_client(client, project_id:, open_on_date:)
    # Load all visible enrollments for the client
    enrollments = load_ar_association(
      client,
      :enrollments,
      scope: Hmis::Hud::Enrollment.viewable_by(current_user).preload(:exit),
    )

    # Filter down by project and date
    enrollments.filter do |en|
      en.open_on_date?(open_on_date) && en.project_pk.to_s == project_id.to_s
    end.min_by { |e| [e.entry_date, e.id] }
  end
end
