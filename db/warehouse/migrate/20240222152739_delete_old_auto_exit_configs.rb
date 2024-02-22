#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class DeleteOldAutoExitConfigs < ActiveRecord::Migration[6.1]
  def change
    drop_table 'hmis_auto_exit_configs' do |t|
      t.integer :length_of_absence_days, null: false
      t.integer :project_type
      t.references :organization
      t.references :project
      t.timestamps
    end
  end
end
