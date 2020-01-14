class AddBedsToProjectTypeCensus < ActiveRecord::Migration[4.2]
  def change
    add_column :nightly_census_by_project_types, :ph_beds, :integer, default: 0
    add_column :nightly_census_by_project_types, :es_beds, :integer, default: 0
    add_column :nightly_census_by_project_types, :th_beds, :integer, default: 0
    add_column :nightly_census_by_project_types, :so_beds, :integer, default: 0
    add_column :nightly_census_by_project_types, :sh_beds, :integer, default: 0
  end
end
