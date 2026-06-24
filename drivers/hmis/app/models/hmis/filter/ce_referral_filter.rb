###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeReferralFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper

  attr_accessor :user

  def initialize(input, user: nil)
    super(input)
    self.user = user
  end

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_referral_statuses)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:with_project_group)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_organizations)).
      yield_self(&method(:with_workflow_template_identifiers)).
      yield_self(&method(:on_current_task_since)).
      yield_self(&method(:with_origin)).
      yield_self(&method(:with_search_term)).
      yield_self(&method(:assigned_to_current_user)).
      yield_self(&method(:assigned_to_user)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_referral_statuses(scope)
    with_filter(scope, :referral_status) do
      custom_statuses = Hmis::Ce::CustomReferralStatus.where(key: input.referral_status)
      scope.where(custom_status: custom_statuses)
    end
  end

  def with_projects(scope)
    with_filter(scope, :project) do
      scope.joins(:target_project).where(p_t[:id].in(input.project))
    end
  end

  def with_project_group(scope)
    with_filter(scope, :project_group_id) do
      project_ids = Hmis::ProjectGroup.project_ids_for(input.project_group_id)
      next scope.none if project_ids.empty?

      scope.joins(:target_project).where(p_t[:id].in(project_ids))
    end
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) do
      scope.joins(:target_project).where(p_t[:project_type].in(input.project_type))
    end
  end

  def with_organizations(scope)
    with_filter(scope, :organization) do
      scope.joins(target_project: :organization).where(o_t[:id].in(input.organization))
    end
  end

  def with_workflow_template_identifiers(scope)
    with_filter(scope, :workflow_template) do
      scope.joins(:workflow_template).where(
        Hmis::WorkflowDefinition::Template.arel_table[:identifier].in(input.workflow_template),
      )
    end
  end

  def on_current_task_since(scope)
    with_filter(scope, :on_current_task_since) do
      # Convert input to application timezone for proper comparison with database timestamps
      filter_time = Time.zone.parse(input.on_current_task_since.to_s)
      scope.joins(:current_steps).
        where(wfe_step_t[:available_at].lt(filter_time))
    end
  end

  def with_origin(scope)
    with_filter(scope, :origin) do
      scope.where(referral_origin: input.origin)
    end
  end

  def with_search_term(scope)
    with_filter(scope, :search_term) do
      scope.matching_search_term(input.search_term)
    end
  end

  def assigned_to_current_user(scope)
    with_filter(scope, :assigned_to_you) do
      next scope unless user

      filter_by_assigned_user(scope, user.id)
    end
  end

  def assigned_to_user(scope)
    with_filter(scope, :assigned_to_user) do
      filter_by_assigned_user(scope, input.assigned_to_user)
    end
  end

  def filter_by_assigned_user(scope, user_id)
    scope.joins(:current_steps).
      merge(Hmis::WorkflowExecution::Step.assigned_to(user_id))
  end
end
