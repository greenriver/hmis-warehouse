###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

require 'memery'

class Hmis::AuthPolicies::UserContext
  include Memery
  attr_accessor :user
  EMPTY_SET = Set.new.freeze

  def initialize(user)
    raise ArgumentError, 'Must be an HMIS user' unless user.is_a?(Hmis::User)

    @user = user
    @access_group_ids_by_project = {}
  end

  memoize def project_role_permissions(project_id)
    access_group_ids = project_access_group_ids(project_id)
    permissions_for_access_group_ids(access_group_ids)
  end

  memoize def data_source_role_permissions(data_source_id)
    access_group_ids = data_source_access_group_ids(data_source_id)
    permissions_for_access_group_ids(access_group_ids)
  end

  def preload_project_dependencies(project_ids)
    results = Hmis::ProjectAccessGroupMember.
      where(project_id: project_ids).
      pluck(:project_id, :access_group_id).
      group_by(&:shift).
      transform_values { |v| v.flatten.compact_blank }
    @access_group_ids_by_project.merge!(results)
  end

  def potential_permissions
    user.roles.flat_map(&:granted_permissions).to_set.freeze
  end

  def referral_project_permissions(referral)
    project_id = referral.opportunity.project_id
    project_role_permissions(project_id)
  end

  memoize def assigned_referral_ids = assigned_referral_steps.pluck(:instance_id).to_set
  memoize def assigned_referral_step_ids = assigned_referral_steps.pluck(:id).to_set

  protected

  def assigned_referral_steps
    Hmis::WorkflowExecution::Step
      .excluding_unavailable
      .joins(:task, :assignments)
      .where(assignments: {user_id: user.id}) # assigned to this user
  end

  memoize def system_access_group_ids(group_name)
    [Collection.system_collection(group_name)&.id].compact
  end

  memoize def permissions_for_access_group_ids(access_group_ids)
    access_group_ids += system_access_group_ids(:data_sources)
    return EMPTY_SET if access_group_ids.blank?

    Role.joins(:access_controls).
      merge(user.access_controls.where(collection_id: access_group_ids)).
      flat_map(&:granted_permissions).to_set.freeze
  end

  def data_source_access_group_ids(data_source_id)
    ids = Hmis::GroupViewableEntity.
      where(entity_type: GrdaWarehouse::DataSource.sti_name).
      where(entity_id: data_source_id).
      where.not(collection_id: nil).
      pluck(:collection_id)
    ids.uniq.sort
  end

  # Returns the access group ids that include this project id
  def project_access_group_ids(project_id)
    preload_project_dependencies([project_id]) unless @access_group_ids_by_project.key?(project_id)
    @access_group_ids_by_project[project_id] ||= []
  end
end
