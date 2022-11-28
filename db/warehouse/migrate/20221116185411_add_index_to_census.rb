class AddIndexToCensus < ActiveRecord::Migration[6.1]
  def change
    add_index :nightly_census_by_projects, :date
    add_index :nightly_census_by_projects, :project_id
  end
end
