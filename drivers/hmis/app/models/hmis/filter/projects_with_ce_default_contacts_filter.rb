###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::ProjectsWithCeDefaultContactsFilter < Hmis::Filter::BaseFilter
  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:with_projects)).
      yield_self(&method(:with_organizations)).
      yield_self(&method(:with_users)).
      yield_self(&method(:clean_scope))
  end

  protected

  def with_projects(scope)
    with_filter(scope, :project) { scope.where(id: input.project) }
  end

  def with_organizations(scope)
    with_filter(scope, :organization) { scope.with_organization_ids(input.organization) }
  end

  def with_users(scope)
    with_filter(scope, :user) do
      return scope unless input.user.present?

      # Get assignment IDs for the given users, and their associated workflow template identifiers.
      assignment_data = Hmis::Ce::DefaultSwimlaneAssignment.
        where(user_id: input.user).
        joins(swimlane: :template).
        pluck(:id, Hmis::WorkflowDefinition::Template.arel_table[:identifier])
      assignment_ids = assignment_data.map(&:first)
      template_identifiers = assignment_data.map(&:second).uniq

      # Find unit groups that use the relevant templates.
      unit_group_scope = Hmis::UnitGroup.where(
        Hmis::UnitGroup.arel_table[:workflow_template_identifier].in(template_identifiers).
          or(Hmis::UnitGroup.arel_table[:direct_referral_workflow_template_identifier].in(template_identifiers)),
      )

      # Prefilter the scope to only include those unit groups' projects.
      # Without this step, the filter returns all projects when the given user has a global default contact.
      # This is confusing in the UI because the row displays "Not applicable" when the template doesn't apply to that project.
      scope = scope.where(id: unit_group_scope.distinct.pluck(:project_id).uniq)

      # Next, join projects scope to assignments that apply to this project (including inherited from org and data source).
      p_t = Hmis::Hud::Project.arel_table
      o_t = Hmis::Hud::Organization.arel_table
      ds_t = GrdaWarehouse::DataSource.arel_table
      a_t = Hmis::Ce::DefaultSwimlaneAssignment.arel_table

      # Build OR conditions for assignments where owner is project, organization, or data source
      project_condition = a_t[:owner_type].eq('Hmis::Hud::Project').and(a_t[:owner_id].eq(p_t[:id]))
      org_condition = a_t[:owner_type].eq('Hmis::Hud::Organization').and(a_t[:owner_id].eq(o_t[:id]))
      data_source_condition = a_t[:owner_type].eq('GrdaWarehouse::DataSource').and(a_t[:owner_id].eq(ds_t[:id]))
      assignment_join_condition = project_condition.or(org_condition).or(data_source_condition)

      # Create Arel join node for assignments
      assignment_join = a_t.create_join(a_t, a_t.create_on(assignment_join_condition), Arel::Nodes::InnerJoin)

      scope.
        joins(:organization, :data_source).
        joins(assignment_join).
        where(a_t[:id].in(assignment_ids)).
        distinct
    end
  end
end
