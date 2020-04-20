class RenameParentsColumn < ActiveRecord::Migration[5.2]
  def change
    rename_column :nightly_census_by_project_clients, :parents, :family_parents
    rename_column :nightly_census_by_projects, :parents, :family_parents
  end
end
