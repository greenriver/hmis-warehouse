###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AutoExitConfig < Hmis::HmisBase
  self.table_name = 'hmis_auto_exit_configs'

  def matching_projects
    scope = Hmis::Hud::Project.all

    scope = scope.where(project_type: project_type) if project_type.present?
    scope = scope.where(organization_id: Hmis::Hud::Organization.find_by(id: organization_id).organization_id) if organization_id.present?
    scope = scope.where(project_id: Hmis::Hud::Project.find_by(id: project_id).project_id) if project_id.present?

    scope
  end

  def self.all_projects_config
    find_by(project_type: nil, organization_id: nil, project_id: nil)
  end

  def self.configs_for_project(project)
    aec_t = Hmis::AutoExitConfig.arel_table

    where(
      aec_t[:project_id].eq(project.id).
      or(aec_t[:organization_id].eq(project.organization.id)).
      or(aec_t[:project_type].eq(project.project_type)),
    )
  end

  def self.config_for_project(project)
    configs = configs_for_project(project)

    return all_projects_config unless configs.exists?

    [
      :project_id,
      :organization_id,
      :project_type,
    ].each do |field|
      scope = configs.where.not(field => nil)
      return scope.first if scope.exists?
    end
  end
end
