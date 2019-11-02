class AddJuveniles < ActiveRecord::Migration
  def change
    add_column :nightly_census_by_project_clients, :juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :literally_homeless_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :system_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :homeless_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :ph_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :es_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :th__juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :so_juveniles, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :sh_juveniles, :jsonb, default: []

    add_column :nightly_census_by_project_types, :literally_homeless_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :system_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :homeless_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :ph_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :es_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :th_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :so_juveniles, :integer, default: 0
    add_column :nightly_census_by_project_types, :sh_juveniles, :integer, default: 0

    add_column :nightly_census_by_projects, :juveniles, :integer, default: 0
  end
end

