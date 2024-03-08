#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddHmisProjectConfigsTable < ActiveRecord::Migration[6.1]
  def change
    create_table(:hmis_project_configs) do |t|
      t.string :type, null: false
      t.boolean :enabled, null: false, default: true
      t.jsonb :config_options
      t.integer :project_type
      t.references :organization
      t.references :project
      t.timestamps
    end
  end
end
