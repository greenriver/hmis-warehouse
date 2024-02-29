#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class MigrateAutoExitRules < ActiveRecord::Migration[6.1]
  def up
    Hmis::AutoExitConfig.transaction do
      Hmis::AutoExitConfig.all.each do |old_auto_exit_config|
        Hmis::ProjectAutoExitConfig.create!(
          project_type: old_auto_exit_config.project_type,
          organization_id: old_auto_exit_config.organization_id,
          project_id: old_auto_exit_config.project_id,
          config_options: { length_of_absence_days: old_auto_exit_config.length_of_absence_days }.to_json,
          created_at: old_auto_exit_config.created_at,
          updated_at: old_auto_exit_config.updated_at,
          enabled: true,
        )
      end
      Hmis::AutoExitConfig.all.each(&:destroy!)
    end

  end

  def down
    Hmis::AutoExitConfig.transaction do
      Hmis::ProjectAutoExitConfig.all.each do |old_auto_exit_config|
        Hmis::AutoExitConfig.create!(
          project_type: old_auto_exit_config.project_type,
          organization_id: old_auto_exit_config.organization_id,
          project_id: old_auto_exit_config.project_id,
          length_of_absence_days: (JSON.parse old_auto_exit_config.config_options)['length_of_absence_days'],
          created_at: old_auto_exit_config.created_at,
          updated_at: old_auto_exit_config.updated_at,
        )
      end
      Hmis::ProjectAutoExitConfig.all.each(&:destroy!)
    end
  end
end
