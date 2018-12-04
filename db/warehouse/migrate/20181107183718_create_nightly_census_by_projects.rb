class CreateNightlyCensusByProjects < ActiveRecord::Migration
  def change
    create_table :nightly_census_by_projects do |t|
      t.date :date, null: false
      t.integer :project_id, null: false

        [ 'veterans', 'non_veterans', 'children', 'adults', 'youth', 'families', 'individuals',
          'parenting_youth', 'parenting_juveniles', 'all_clients', 'beds' ].each do |count|
          t.integer count, default: 0
        end

      t.timestamps null: false
    end
  end
end
