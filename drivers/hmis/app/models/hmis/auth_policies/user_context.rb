###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'

# Facade that provides authorization context for policy objects.
# Delegates complex data loading and caching to specialized loader classes.
#
# This context is shared across all policy objects for a single user/request,
# enabling efficient bulk data loading and caching.
class Hmis::AuthPolicies::UserContext
  include Memery

  attr_reader :user
  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'Must be an HMIS user' unless user.is_a?(Hmis::User)
    raise ArgumentError, 'Must be tied to an HMIS data source' unless user.hmis_data_source_id.present?

    @user = user
    # Current data source (set by the controller based on which HMIS the request is coming from)
    @data_source_id = user.hmis_data_source_id
  end

  # Set of permissions that the user has for some entity in the current data source
  # Examples:
  # - User has can_view_project for a Project in this data source => global_permissions includes can_view_project
  # - User has can_view_project for a Project in another data source => global_permissions does not include can_view_project
  memoize def global_permissions
    data_source = GrdaWarehouse::DataSource.find(@data_source_id)

    # All access groups that grant any permission on any entity in the data source
    access_group_ids = ::Hmis::GroupViewableEntity.
      includes_any_entity_in_data_source(data_source).
      pluck(:collection_id)
    permission_loader.for_access_group_ids(access_group_ids)
  end

  # Set of permissions that the user has for the given project
  def project_permissions(project_id)
    return EMPTY_SET if project_id.blank?
    return EMPTY_SET unless project_belongs_to_current_data_source?(project_id)

    access_group_ids = project_access_group_loader.get(project_id)
    permission_loader.for_access_group_ids(access_group_ids)
  end

  # Set of permissions that the user has for the given organization.
  # Unlike for Project, where we built loaders to ensure efficient queries against multiple projects,
  # we can just load all permissions for the given organization directly,
  # because the organization policy methods are only ever checked against one organization at a time.
  # We can update this internally without changing the HmisOrganizationPolicy's interface if that changes.
  def organization_permissions(organization)
    return EMPTY_SET unless organization_belongs_to_current_data_source?(organization)

    access_group_ids = Hmis::GroupViewableEntity.includes_organization(organization).pluck(:collection_id).to_set
    permission_loader.for_access_group_ids(access_group_ids)
  end

  def preload_project_dependencies(project_ids)
    project_data_source_loader.preload(project_ids)
    project_access_group_loader.preload(project_ids)
  end

  def preload_client_dependencies(client_ids)
    client_project_loader.preload(client_ids)
    project_ids = client_project_loader.cached_project_ids
    project_data_source_loader.preload(project_ids)
    project_access_group_loader.preload(project_ids)
  end

  # Client permissions are based on the user's permissions at projects they are enrolled in.
  # If they have no enrollments, it's based on the user's global permissions.
  def client_permissions(client_id)
    project_ids = client_project_loader.get(client_id)

    if project_ids.empty?
      # Client has no enrollments - use global permissions
      global_permissions
    else
      # Client has enrollments - union permissions from all enrolled projects
      project_data_source_loader.preload(project_ids)
      project_access_group_loader.preload(project_ids)
      project_ids.flat_map { |id| project_permissions(id).to_a }.to_set.freeze
    end
  end

  def preload_referral_dependencies(referral_ids)
    ce_referral_project_loader.preload(referral_ids)
    ce_referral_source_project_loader.preload(referral_ids)

    # preload project ids associated with the referrals (including both source and target projects)
    project_ids = (ce_referral_project_loader.cached_project_ids + ce_referral_source_project_loader.cached_project_ids).uniq
    project_data_source_loader.preload(project_ids)
    project_access_group_loader.preload(project_ids)
  end

  # CE Referral assignment data
  def assigned_referral_instance_ids
    ce_referral_assignment_loader.assigned_referral_instance_ids
  end

  def assigned_referral_step_ids
    ce_referral_assignment_loader.assigned_referral_step_ids
  end

  def referral_project_id(referral_id)
    ce_referral_project_loader.get(referral_id)
  end

  def referral_source_project_id(referral_id)
    ce_referral_source_project_loader.get(referral_id)
  end

  # Clear cached assignment data when step assignments change during mutations
  def clear_referral_assignment_cache!
    ce_referral_assignment_loader.clear_cache!
  end

  protected

  def project_belongs_to_current_data_source?(project_id)
    project_data_source_id = project_data_source_loader.get(project_id)
    return true if project_data_source_id == user.hmis_data_source_id

    Sentry.capture_message(
      "HMIS Data Source Mismatch: User #{user.id} (DS: #{user.hmis_data_source_id}) " \
      "attempted to access Project #{project_id} (DS: #{project_data_source_id})",
    )
    false
  end

  def organization_belongs_to_current_data_source?(organization)
    return true if organization.data_source_id == user.hmis_data_source_id

    Sentry.capture_message(
      "HMIS Data Source Mismatch: User #{user.id} (DS: #{user.hmis_data_source_id}) " \
      "attempted to access Organization #{organization.id} (DS: #{organization.data_source_id})",
    )

    false
  end

  # Context loaders (memoized for request-level caching)
  memoize def project_data_source_loader
    Hmis::AuthPolicies::ContextLoaders::ProjectDataSourceLoader.new
  end

  memoize def permission_loader
    Hmis::AuthPolicies::ContextLoaders::HmisPermissionLoader.new(user)
  end

  memoize def project_access_group_loader
    Hmis::AuthPolicies::ContextLoaders::HmisProjectAccessGroupLoader.new
  end

  memoize def ce_referral_assignment_loader
    Hmis::AuthPolicies::ContextLoaders::CeReferralAssignmentLoader.new(user)
  end

  memoize def ce_referral_project_loader
    Hmis::AuthPolicies::ContextLoaders::CeReferralProjectLoader.new
  end

  memoize def ce_referral_source_project_loader
    Hmis::AuthPolicies::ContextLoaders::CeReferralSourceProjectLoader.new
  end

  memoize def client_project_loader
    Hmis::AuthPolicies::ContextLoaders::ClientProjectLoader.new
  end
end
