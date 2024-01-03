class CreateExternalPermissionTables < ActiveRecord::Migration[6.1]
  def change
    create_table :external_reporting_project_permissions do |t|
      t.references :user, null: false
      t.references :project, null: false
      t.string :permission, null: false
      t.timestamps
    end

    create_table :external_reporting_cohort_permissions do |t|
      t.references :user, null: false
      t.references :cohort, null: false
      t.string :permission, null: false
      t.timestamps
    end
  end
end
