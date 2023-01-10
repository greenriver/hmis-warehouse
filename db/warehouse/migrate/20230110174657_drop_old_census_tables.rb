class DropOldCensusTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :nightly_census_by_project_types
    drop_table :nightly_census_by_project_type_clients
    drop_table :nightly_census_by_project_clients
    drop_table :censuses_averaged_by_year
  end
end
