###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeReferralFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_referral_statuses)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_workflow_template_identifiers)).
      yield_self(&method(:on_current_task_since)).
      yield_self(&method(:with_origin)).
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
      scope.joins(:opportunity).where(opp_t[:project_id].in(input.project))
    end
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) do
      scope.joins(opportunity: :project).where(p_t[:project_type].in(input.project_type))
    end
  end

  def with_workflow_template_identifiers(scope)
    with_filter(scope, :workflow_template) do
      scope.joins(:opportunity).where(opp_t[:workflow_template_identifier].in(input.workflow_template))
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
end
