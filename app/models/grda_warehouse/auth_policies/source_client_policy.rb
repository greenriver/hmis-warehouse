###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

  # Hand-written, not added to the permission-mapping array above: there is no
  # can_view_partial_ssn role permission to map from.
  def can_view_partial_ssn?
    true
  end

  # can the user see the full client dash page and additional details?
  memoize def can_view?
    return true if resource_permissions.include?(:can_view_clients)
    return roi_authorized? if resource_permissions.include?(:can_view_client_enrollments_with_roi)

    false
  end

  def can_view_supplemental_data?
    # supplemental data sets do not support legacy role-based permissions
    return false unless user.using_acls?

    # permission check
    return false unless resource_permissions.include?(:can_view_supplemental_client_data)

    # ensure the client has an active roi
    return false unless roi_authorized?

    return true
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

  # NOTE: loads through context.client_roi_loader; preload it when authorizing many clients to avoid N+1 queries
  #
  # An ROI confers visibility when:
  # - the source client is in a data source with `obey_consent=true`
  # - the destination client has a ClientRoiAuthorization.visible_in_cocs row for one of the user's CoCs, or all CoCs.
  #   Under Consent::Default a partial (CAS-only) release does not count
  # - the user has a role on the source client's project granting `can_view_client_enrollments_with_roi`
  #   (view) or `can_search_clients_with_roi` (search)
  # ROI does not confer additional permissions such as name or SSN visibility.
  def roi_authorized?
    return false unless client.data_source&.obey_consent?

    destination = client.destination_client
    return false unless destination

    context.client_roi_loader.get(destination.id)
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
      # - See the searchable_to method in the Client extension (drivers/client_access_control/app/models/client_access_control/extensions/grda_warehouse/hud/client_extension.rb) which includes all clients in the search scope if the user has the can_search_all_clients permission
      results.merge(legacy_permissions & BASIC_CLIENT_PII_PERMS)
    end

    # check ROI if the window config requires release (the "can_*_with_roi" permissions are not relevant in this case)
    return if context.legacy_window_access_requires_release? && !roi_authorized?

    results.merge(legacy_permissions)
  end

  # permissions the user has through association with the client's enrolled projects, orgs, project groups, etc.
  def add_project_based_permissions(results)
    context.enrolled_project_ids_for_client(client_id).each do |project_id|
      results.merge(context.project_role_permissions(project_id))
    end
  end

  # permissions the user has directly on the client (for destination clients with no enrollments in authoritative data sources)
  def add_direct_client_permissions(results)
    results.merge(context.direct_client_role_permissions(client_id))
  end
end
