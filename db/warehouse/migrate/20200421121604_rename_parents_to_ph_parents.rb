class RenameParentsToPhParents < ActiveRecord::Migration[5.2]
  def change
    rename_column :nightly_census_by_project_type_clients, :literally_homeless_parents, :literally_homeless_family_parents
    rename_column :nightly_census_by_project_type_clients, :system_parents, :system_family_parents
    rename_column :nightly_census_by_project_type_clients, :homeless_parents, :homeless_family_parents
    rename_column :nightly_census_by_project_type_clients, :ph_parents, :ph_family_parents
    rename_column :nightly_census_by_project_type_clients, :es_parents, :es_family_parents
    rename_column :nightly_census_by_project_type_clients, :th_parents, :th_family_parents
    rename_column :nightly_census_by_project_type_clients, :so_parents, :so_family_parents
    rename_column :nightly_census_by_project_type_clients, :sh_parents, :sh_family_parents

    rename_column :nightly_census_by_project_types, :literally_homeless_parents, :literally_homeless_family_parents
    rename_column :nightly_census_by_project_types, :system_parents, :system_family_parents
    rename_column :nightly_census_by_project_types, :homeless_parents, :homeless_family_parents
    rename_column :nightly_census_by_project_types, :ph_parents, :ph_family_parents
    rename_column :nightly_census_by_project_types, :es_parents, :es_family_parents
    rename_column :nightly_census_by_project_types, :th_parents, :th_family_parents
    rename_column :nightly_census_by_project_types, :so_parents, :so_family_parents
    rename_column :nightly_census_by_project_types, :sh_parents, :sh_family_parents
  end
end
