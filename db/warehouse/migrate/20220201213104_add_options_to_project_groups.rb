class AddOptionsToProjectGroups < ActiveRecord::Migration[5.2]
  def change
    add_column :project_groups, :options, :jsonb, default: {}
  end
end
