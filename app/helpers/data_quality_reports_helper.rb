###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module DataQualityReportsHelper
  # Renders the block as plain text when the user can't open the client-level support page.
  def dq_support_link_to(path_parts, params, html_options = {}, &block)
    return capture(&block) unless dq_support_linkable?(params)

    link_to(polymorphic_path(path_parts, params), html_options, &block)
  end

  # Blank when the user can't open support, so chart click handlers have no URL to follow.
  def dq_support_url(path_parts, params)
    return '' unless dq_support_linkable?(params)

    polymorphic_path(path_parts, params)
  end

  # Older reports stored project and organization names in the report hash. Display names come
  # from the live projects instead, so they follow the viewer's confidential-name permission.
  def dq_stored_name_value(key, value)
    case key.to_sym
    when :agency_name
      dq_report_project_ids.map { |id| dq_project_organization_name(id) }.uniq.join(', ')
    when :project_name
      dq_report_project_ids.map { |id| dq_project_name(id) }.uniq.join(', ')
    else
      value
    end
  end

  def dq_project_name(project_id)
    dq_projects([project_id])[project_id]&.name(current_user) || GrdaWarehouse::Hud::Project.confidential_project_name
  end

  def dq_project_organization_name(project_id)
    dq_projects([project_id])[project_id]&.organization_name(current_user) || GrdaWarehouse::Hud::Organization.confidential_organization_name
  end

  private def dq_report_project_ids
    ids = @report.project_group_id.present? ? @report.project_group.projects.ids : [@report.project_id]
    ids.compact
  end

  private def dq_projects(ids)
    @dq_projects ||= {}
    missing = ids.uniq - @dq_projects.keys
    if missing.any?
      current_user.policy_context.preload_project_dependencies(missing)
      found = GrdaWarehouse::Hud::WithDeleted::Project.where(id: missing).index_by(&:id)
      missing.each { |id| @dq_projects[id] = found[id] }
    end
    @dq_projects
  end

  # Only individual-style support requests are served; key-style links on older reports would 404.
  private def dq_support_linkable?(params)
    can_view_dq_support? && params[:individual].present?
  end
end
