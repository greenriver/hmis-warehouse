# frozen_string_literal: true

class AddHmisProjectGroups < ActiveRecord::Migration[7.1]
  def up
    # HMIS equivalent of project_groups table
    create_table :hmis_project_groups do |t|
      t.string :name, null: false
      t.references :data_source, null: false # HMIS Project Group must belong to 1 data source
      t.jsonb :inclusion_criteria, null: false # Criteria for project inclusion in the group
      t.jsonb :exclusion_criteria, null: true # Criteria for project exclusion from the group
      t.timestamps
      t.timestamp :deleted_at
    end

    # Make project group names unique per data source
    add_index :hmis_project_groups, [:data_source_id, :name], unique: true, where: 'deleted_at IS NULL', name: :uidx_hmis_project_groups_on_data_source_and_name

    # HMIS equivalent of project_project_groups table (join table)
    create_table :hmis_project_project_groups do |t|
      t.references :hmis_project_group, null: false, foreign_key: true
      t.references :project, null: false
      t.timestamps
    end
  end

  def down
    drop_table :hmis_project_groups, force: :cascade
    drop_table :hmis_project_project_groups
  end
end
