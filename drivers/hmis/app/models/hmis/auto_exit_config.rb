###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# TODO: This file should be removed after migration 20240221195839 runs
# and at that point we should add a migration to remove the old database table hmis_auto_exit_configs, as well
class Hmis::AutoExitConfig < Hmis::HmisBase
  self.table_name = 'hmis_auto_exit_configs'

  belongs_to :project, optional: true, class_name: 'Hmis::Hud::Project'
  belongs_to :organization, optional: true, class_name: 'Hmis::Hud::Organization'

  validates :length_of_absence_days, numericality: { greater_than_or_equal_to: 30 }

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
