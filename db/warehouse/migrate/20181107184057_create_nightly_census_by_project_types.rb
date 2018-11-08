class CreateNightlyCensusByProjectTypes < ActiveRecord::Migration
  def change
    create_table :nightly_census_by_project_types do |t|
      t.date :date, null: false

      [  'literally_homeless', 'system', 'homeless', 'ph', 'es', 'th', 'so', 'sh' ].each do |type|
        [ 'veterans', 'non_veterans', 'children', 'adults', 'youth', 'families', 'individuals',
          'parenting_youth', 'parenting_juveniles', 'all_clients', 'beds' ].each do |count|
          t.integer "#{type}_#{count}", default: 0
        end
      end

      t.timestamps null: false
    end
  end
end
