###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# @see docs/features/warehouse/warehouse-auth-policies.md
class GrdaWarehouse::AuthPolicies::DataQualityReportPolicy < GrdaWarehouse::AuthPolicies::BasePolicy
  REPORT_DEFINITION_URL = 'warehouse_reports/project/data_quality'

  def self.report_definition_viewable?(user)
    return false unless user&.can_view_assigned_reports?

    report_definition_scope.viewable_by(user).exists?
  end

  # Under ACLs the project must share a collection with the report definition, so one access control grants both.
  def self.reportable_project_ids(user)
    return GrdaWarehouse::Hud::Project.none.select(:id) unless report_definition_viewable?(user)

    scope = GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports)
    scope = scope.where(id: GrdaWarehouse::Hud::Project.project_ids_in_collections(report_collection_ids(user))) if user.using_acls?
    scope.select(:id)
  end

  def self.reportable_project_group_ids(user)
    return GrdaWarehouse::ProjectGroup.none.select(:id) unless report_definition_viewable?(user)
    return GrdaWarehouse::ProjectGroup.viewable_by(user).select(:id) unless user.using_acls?

    group_ids = GrdaWarehouse::GroupViewableEntity.where(
      collection_id: report_collection_ids(user),
      entity_type: GrdaWarehouse::ProjectGroup.sti_name,
    ).select(:entity_id)
    GrdaWarehouse::ProjectGroup.where(id: group_ids).select(:id)
  end

  # Contacts on the project or its organization can view the report without any other access to the project.
  def self.viewable_reports(user)
    return report_scope.none unless report_definition_viewable?(user)

    reporting = report_scope.where(project_id: reportable_project_ids(user)).
      or(report_scope.where(project_group_id: reportable_project_group_ids(user)))
    reporting = reporting.where(requestor_id: user.id) unless user.can_view_all_reports?

    contact_project_ids = contact_project_ids(user)
    contact_group_ids = GrdaWarehouse::ProjectGroup.joins(:projects).
      merge(GrdaWarehouse::Hud::Project.where(id: contact_project_ids)).
      select(:id)
    contact = report_scope.where(project_id: contact_project_ids).
      or(report_scope.where(project_group_id: contact_group_ids))

    reporting.or(contact)
  end

  def can_view?
    viewable?
  end

  def can_view_client_details?
    viewable? && client_projects_viewable?
  end

  protected

  def validate_resource!(arg)
    ensure_arg_type!(arg, GrdaWarehouse::WarehouseReports::Project::DataQuality::Base)
  end

  memoize def viewable?
    self.class.viewable_reports(user).where(id: resource.id).exists?
  end

  # A group report's support rows can come from any project in the group, so every project must be client-viewable.
  memoize def client_projects_viewable?
    return false unless user.can_view_clients?

    project_ids = if resource.project_group_id.present?
      GrdaWarehouse::Hud::Project.joins(:project_groups).
        merge(GrdaWarehouse::ProjectGroup.where(id: resource.project_group_id)).
        distinct.pluck(:id)
    else
      [resource.project_id]
    end
    return false if project_ids.empty?

    viewable_count = GrdaWarehouse::Hud::Project.
      viewable_by(user, permission: :can_view_clients, confidential_scope_limiter: :all).
      where(id: project_ids).
      count
    viewable_count == project_ids.size
  end

  class << self
    private

    def report_scope
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
    end

    def report_definition_scope
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: REPORT_DEFINITION_URL)
    end

    def report_collection_ids(user)
      GrdaWarehouse::GroupViewableEntity.where(
        collection_id: user.collections_for_permission(:can_view_assigned_reports),
        entity_type: GrdaWarehouse::WarehouseReports::ReportDefinition.sti_name,
        entity_id: report_definition_scope.select(:id),
      ).distinct.pluck(:collection_id)
    end

    def contact_project_ids(user)
      organization_project_ids = GrdaWarehouse::Hud::Project.joins(:organization).
        merge(
          GrdaWarehouse::Hud::Organization.where(
            id: GrdaWarehouse::Contact::Organization.where(user_id: user.id).select(:entity_id),
          ),
        ).select(:id)

      GrdaWarehouse::Hud::Project.where(id: GrdaWarehouse::Contact::Project.where(user_id: user.id).select(:entity_id)).
        or(GrdaWarehouse::Hud::Project.where(id: organization_project_ids)).
        select(:id)
    end
  end
end
