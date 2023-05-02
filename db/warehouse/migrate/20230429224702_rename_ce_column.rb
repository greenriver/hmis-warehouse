class RenameCeColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :system_pathways_clients, :ce, :involves_ce
    remove_column :system_pathways_enrollments, :disabling_condition, :boolean
    add_column :system_pathways_enrollments, :disabling_condition, :integer
  end
end
