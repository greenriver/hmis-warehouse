class AddYouthFamilies < ActiveRecord::Migration[5.2]
  def change
    add_column :nightly_census_by_project_clients, :youth_families, :jsonb, default: []
    add_column :nightly_census_by_projects, :youth_families, :integer, default: 0

    add_column :nightly_census_by_project_type_clients, :literally_homeless_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :system_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :homeless_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :ph_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :es_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :th_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :so_youth_families, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :sh_youth_families, :jsonb, default: []

    add_column :nightly_census_by_project_types, :literally_homeless_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :system_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :homeless_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :ph_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :es_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :th_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :so_youth_families, :integer, default: 0
    add_column :nightly_census_by_project_types, :sh_youth_families, :integer, default: 0
  end
end
