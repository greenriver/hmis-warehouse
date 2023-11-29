###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::AutoExitConfig < Hmis::HmisBase
  self.table_name = 'hmis_auto_exit_configs'

  def self.default_config
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

    return default_config unless configs.exists?

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
