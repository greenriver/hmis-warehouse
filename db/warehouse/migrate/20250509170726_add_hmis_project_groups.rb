class AddHmisProjectGroups < ActiveRecord::Migration[7.1]
  def change
    # HMIS equivalent of project_groups table
    create_table :hmis_project_groups do |t|
      t.string :name, null: false
      t.jsonb :inclusion_criteria, null: false
      t.jsonb :exclusion_criteria, null: true
      t.timestamps
      t.timestamp :deleted_at
    end

    add_index :hmis_project_groups, :name, unique: true, where: "deleted_at IS NULL", name: :uidx_hmis_project_groups_on_name

    # HMIS equivalent of project_project_groups table (join table)
    create_table :hmis_project_project_groups do |t|
      t.references :hmis_project_group, null: false, foreign_key: true
      t.references :project, null: false
      t.timestamps
    end
  end
end
