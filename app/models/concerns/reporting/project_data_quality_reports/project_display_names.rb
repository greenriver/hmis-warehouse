###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reporting::ProjectDataQualityReports::ProjectDisplayNames
  extend ActiveSupport::Concern

  # Warehouse project id => name shown to the user, unique within the report.
  # Charts key series by these names and the JS maps a clicked name back to a
  # project id, so masked confidential projects need distinct names: duplicates
  # get " (2)", " (3)", ... in project id order.
  def project_display_names(user: viewing_user)
    @project_display_names ||= {}
    @project_display_names[user&.id] ||= begin
      hud_projects = projects.index_by(&:id)
      rows = report_projects.index_by(&:project_id)
      taken = Set.new
      name_project_ids.index_with do |id|
        base = hud_projects[id]&.name(user) || rows[id]&.safe_project_name(user) || 'Project Missing'
        name = base
        suffix = 1
        name = "#{base} (#{suffix += 1})" while taken.include?(name)
        taken << name
        name
      end
    end
  end

  def preload_project_policies(user)
    ids = name_project_ids
    user&.policy_context&.preload_project_dependencies(ids) if ids.any?
  end

  def project_display_name(project_id, user: viewing_user)
    project_display_names(user: user)[project_id]
  end

  private def name_project_ids
    (projects.map(&:id) + report_projects.map(&:project_id)).compact.uniq.sort
  end
end
