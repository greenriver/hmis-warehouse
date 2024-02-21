#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class Hmis::ProjectConfig < Hmis::HmisBase
  self.abstract_class = true
  self.table_name = 'hmis_project_configs'

  # todo @martha - validate at least one of project, etc.
  belongs_to :project, optional: true, class_name: 'Hmis::Hud::Project'
  belongs_to :organization, optional: true, class_name: 'Hmis::Hud::Organization'

  AUTO_EXIT_CONFIG = 'Hmis::ProjectAutoExitConfig'.freeze
  AUTO_ENTER_CONFIG = 'Hmis::ProjectAutoEnterConfig'.freeze
  TYPE_OPTIONS = [AUTO_EXIT_CONFIG, AUTO_ENTER_CONFIG].freeze
  validates :type, inclusion: { in: TYPE_OPTIONS }

  # TODO: This method and the below are repeated code in auto_exit_config.rb
  # In the future auto_exit_config.rb will be fully replaced by project_auto_exit_config.rb
  def self.configs_for_project(project)
    pc_t = Hmis::ProjectConfig.arel_table

    where(
      pc_t[:project_id].eq(project.id).
        or(pc_t[:organization_id].eq(project.organization.id)).
        or(pc_t[:project_type].eq(project.project_type)),
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
