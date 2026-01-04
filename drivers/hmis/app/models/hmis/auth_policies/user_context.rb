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
# It is scoped to exactly one HMIS data source (to prevent cross-data-source leakage).
class Hmis::AuthPolicies::UserContext
  include Memery

  attr_reader :user, :data_source_id
  EMPTY_SET = Set.new.freeze

  def initialize(user, data_source_id:)
    raise ArgumentError, 'Must be an HMIS user' unless user.is_a?(Hmis::User)
    raise ArgumentError, 'Must be an HMIS data source' unless GrdaWarehouse::DataSource.hmis.exists?(id: data_source_id)

    @user = user
    @data_source_id = data_source_id
  end

  # Global user permissions (across all projects/entities)
  memoize def potential_permissions
    user.roles.flat_map(&:granted_permissions).to_set.freeze
  end

  # Project-specific permissions
  def project_permissions(project_id)
    access_group_ids = project_access_group_loader.get(project_id)
    permission_loader.for_access_group_ids(access_group_ids)
  end

  def preload_project_dependencies(project_ids)
    project_access_group_loader.preload(project_ids)
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
    Hmis::AuthPolicies::ContextLoaders::HmisProjectAccessGroupLoader.new(data_source_id: @data_source_id)
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
end
