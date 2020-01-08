class AddUnnacompaniedMinorsToCensuses < ActiveRecord::Migration[5.2]
  def change
    add_column :nightly_census_by_project_clients, :unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_projects, :unaccompanied_minors, :integer, default: 0

    add_column :nightly_census_by_project_type_clients, :literally_homeless_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :system_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :homeless_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :ph_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :es_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :th_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :so_unaccompanied_minors, :jsonb, default: []
    add_column :nightly_census_by_project_type_clients, :sh_unaccompanied_minors, :jsonb, default: []

    add_column :nightly_census_by_project_types, :literally_homeless_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :system_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :homeless_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :ph_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :es_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :th_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :so_unaccompanied_minors, :integer, default: 0
    add_column :nightly_census_by_project_types, :sh_unaccompanied_minors, :integer, default: 0

  end
end
