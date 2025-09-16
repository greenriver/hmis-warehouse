###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeOpportunityFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_statuses)).
      yield_self(&method(:with_projects)).
      yield_self(&method(:with_project_types)).
      yield_self(&method(:with_organizations)).
      yield_self(&method(:available_on_date)).
      yield_self(&method(:with_workflow_template_identifiers)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_statuses(scope)
    with_filter(scope, :status) { scope.where(status: input.status) }
  end

  def with_projects(scope)
    with_filter(scope, :project) do
      scope.where(project_id: input.project)
    end
  end

  def with_project_types(scope)
    with_filter(scope, :project_type) do
      scope.joins(:project).where(p_t[:project_type].in(input.project_type))
    end
  end

  def with_organizations(scope)
    with_filter(scope, :organization) do
      scope.joins(project: :organization).where(o_t[:id].in(input.organization))
    end
  end

  def available_on_date(scope)
    with_filter(scope, :available_on_date) do
      scope.available_on_date(input.available_on_date)
    end
  end

  def with_workflow_template_identifiers(scope)
    with_filter(scope, :workflow_template) do
      scope.where(workflow_template_identifier: input.workflow_template)
    end
  end
end
