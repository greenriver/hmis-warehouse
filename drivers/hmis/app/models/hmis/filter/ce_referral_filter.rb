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
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_workflow_template_identifiers)).
      yield_self(&method(:on_current_step_since)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) { scope.where(status: input.status) }
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

  def on_current_step_since(scope)
    with_filter(scope, :on_current_step_since) do
      scope.joins(:current_steps).where(wfe_step_t[:updated_at].lt(input.on_current_step_since)).distinct
    end
  end
end
