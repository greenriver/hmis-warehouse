class AddHmisAutoExitConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :Exit, :auto_exited, :datetime, null: true

    create_table(:hmis_auto_exit_configs) do |t|
      t.integer :length_of_absence_days, null: false, default: 30
      t.integer :project_type
      t.integer :organization_id
      t.integer :project_id
      t.timestamps
    end
  end
end
