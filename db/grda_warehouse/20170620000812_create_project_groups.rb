class CreateProjectGroups < ActiveRecord::Migration
  def change
    create_table :project_groups do |t|
      t.string :name, null: false
      t.timestamps
      t.datetime :deleted_at
    end

    create_table :project_project_groups do |t|
      t.references :project_group
      t.references :project
      t.timestamps
      t.datetime :deleted_at
    end
  end
end
