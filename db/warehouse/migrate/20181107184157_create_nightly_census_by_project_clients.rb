class CreateNightlyCensusByProjectClients < ActiveRecord::Migration
  def change
    create_table :nightly_census_by_project_clients do |t|
      t.date :date, null: false
      t.datetime :calculated_at, null: false
      t.string :project_id, null: false

      [ 'veterans', 'non_veterans', 'children', 'adults', 'youth', 'families', 'individuals',
        'parenting_youth', 'parenting_juveniles', 'all_clients', 'beds' ].each do |count|
        t.json count, default: []
      end

      t.timestamps null: false
    end
  end
end
