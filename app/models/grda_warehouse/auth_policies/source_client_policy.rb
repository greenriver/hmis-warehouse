###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::AuthPolicies::SourceClientPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  # expose role permissions. Optionally rename the permission
  [
    [:can_view_client_name, :can_view_name?],
    [:can_view_client_photo, :can_view_photo?],
    [:can_view_full_dob],
    [:can_view_full_ssn],
    [:can_view_hiv_status],
  ].each do |permission, method_name|
    method_name ||= :"#{permission}?"
    define_method(method_name) do
      resource_permissions.include?(permission)
    end
  end

  # can the user see the full client dash page and additional details?
  memoize def can_view?
    return true if resource_permissions.include?(:can_view_clients)
    return roi_authorized? if resource_permissions.include?(:can_view_client_enrollments_with_roi)

    false
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::Hud::Client)
    raise ArgumentError 'Must be a source client' if arg.destination?
  end

  def client_id
    resource.id
  end

  def client
    resource
  end

  # NOTE: this will query `destination_client.roi_authorizations` which could be a source of N+1 queries if authorizing
  # multiple clients
  #
  # An ROI confers some level of visibility to the client under the following circumstances:
  # - the source client must be in a data source with `obeys_consent=true`
  # - the ROI has a valid status (not revoked). ROI fields are stored on the destination client record (for now)
  # - if the ROI is restricted to certain COCs then the user's COCs must match
  # - the user has a role granting permission on source client project as follows:
  #   - if the user has `can_search_client_with_roi`, we grant `can_search_own_clients` and `can_search_all_clients`
  #   - if the user has `can_view_client_enrollments_with_roi`, we grant `can_view_clients`
  # - ROI does not confer additional permissions. Additional permissions are identical to clients without an ROI, such as via direct assignment
  memoize def roi_authorized?
    return false unless client.data_source&.obey_consent?

    destination = client.destination_client
    return false unless destination

    roi_authorizations = destination.roi_authorizations.order(:id).filter(&:active?)
    return false if roi_authorizations.blank?

    roi_authorizations.any? { |a| a.matches_coc_codes?(user.coc_codes) }
  end

  # a set of permissions the user has for either the project or the client which would grant them access to this client
  memoize def resource_permissions
    results = Set.new
    add_legacy_data_source_permissions(results)
    add_project_based_permissions(results)
    add_direct_client_permissions(results)
    results
  end

  BASIC_CLIENT_PII_PERMS = Set.new([:can_view_client_name, :can_view_client_photo, :can_view_full_dob]).freeze

  # Window data sources are a deprecated legacy client data sharing mechanic, replaced by a System Collection when using Access Controls-based permissions
  def add_legacy_data_source_permissions(results)
    # is this a user with legacy role-based perms?
    legacy_permissions = context.legacy_permissions
    return unless legacy_permissions.present?

    # is the client in a window data source?
    return unless context.legacy_window_data_source_ids.include?(client.data_source_id)

    # Legacy visibility rules for client attributes:
    # If a user has either 'can_view_clients' or 'can_search_all_clients' permission, AND they
    # have another permission (like viewing names), then the user is granted that permission
    # for ANY client in window data sources, bypassing ROI requirements.
    #
    # For example: A user with both 'can_view_clients' and 'can_view_name' permissions can
    # see names of all clients in window data sources, regardless of the client's ROI.
    #
    # Historical context: This behavior comes from the legacy role-based system where client
    # visibility was considered "global" if the user could access clients in either "search"
    # or "view" contexts, but only for "window" data sources.
    if legacy_permissions.include?(:can_view_clients)
      # all the legacy perms apply to the client
      results.merge(legacy_permissions)
      # early return since there's no point in checking ROI
      return
    elsif legacy_permissions.include?(:can_search_all_clients)
      # The can_search_all_clients confers a reduced set or permissions. This is more restricted
      # than the historic permissions. This is okay since search has limited client details.
      #
      # Notes
      # - The client search controller (ClientAccessControl::ClientsController) also requires can_search_window || can_use_strict_search. We aren't enforcing that here.
      # - See the searchable_to method in the Client extension (drivers/client_access_control/extensions/grda_warehouse/hud/client_extension.rb) which includes all clients in the search scope if the user has the can_search_all_clients permission
      results.merge(legacy_permissions & BASIC_CLIENT_PII_PERMS)
    end

    # check ROI if the window config requires release (the "can_*_with_roi" permissions are not relevant in this case)
    return if context.legacy_window_access_requires_release? && !roi_authorized?

    results.merge(legacy_permissions)
  end

  # permissions the user has through association with the client's enrolled projects, orgs, project groups, etc.
  def add_project_based_permissions(results)
    enrolled_project_ids = GrdaWarehouse::Hud::Project.
      joins(:clients).
      merge(GrdaWarehouse::Hud::Client.where(id: client_id)).
      distinct.
      pluck(:id)
    enrolled_project_ids.each do |project_id|
      results.merge(context.project_role_permissions(project_id))
    end
  end

  # permissions the user has directly on the client (for destination clients with no enrollments in authoritative data sources)
  def add_direct_client_permissions(results)
    results.merge(context.direct_client_role_permissions(client_id))
  end
end
