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

    @user = user
  end

  # Global user permissions (across all projects/entities)
  memoize def potential_permissions
    user.roles.flat_map(&:granted_permissions).to_set.freeze
  end

  memoize def global_permissions
    permissions = user.roles.flat_map(&:granted_permissions).to_set
    permission_loader.apply_permission_requirements(permissions).freeze
  end

  # Project-specific permissions
  def project_permissions(project_id)
    access_group_ids = project_access_group_loader.get(project_id)
    permission_loader.for_access_group_ids(access_group_ids)
  end

  def preload_project_dependencies(project_ids)
    project_access_group_loader.preload(project_ids)
  end

  # Client permissions are based on the user's permissions at projects they are enrolled in.
  # If they have no enrollments, it's based on the user's global permissions.
  def client_permissions(client_id)
    project_ids = client_project_loader.get(client_id)

    if project_ids.empty?
      # Client has no enrollments - use global permissions
      potential_permissions
    else
      # Client has enrollments - union permissions from all enrolled projects
      project_access_group_loader.preload(project_ids)
      project_ids.flat_map { |id| project_permissions(id).to_a }.to_set.freeze
    end
  end

  def preload_referral_dependencies(referral_ids)
    ce_referral_project_loader.preload(referral_ids)
    ce_referral_source_project_loader.preload(referral_ids)
    project_access_group_loader.preload(ce_referral_project_loader.cached_project_ids + ce_referral_source_project_loader.cached_project_ids)
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

  # Context loaders (memoized for request-level caching)
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
