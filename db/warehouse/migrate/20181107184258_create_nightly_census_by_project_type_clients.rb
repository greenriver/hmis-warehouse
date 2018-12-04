class CreateNightlyCensusByProjectTypeClients < ActiveRecord::Migration
  def change
    create_table :nightly_census_by_project_type_clients do |t|
      t.date :date, null: false

      [  'literally_homeless', 'system', 'homeless', 'ph', 'es', 'th', 'so', 'sh' ].each do |type|
        [ 'veterans', 'non_veterans', 'children', 'adults', 'youth', 'families', 'individuals',
          'parenting_youth', 'parenting_juveniles', 'all_clients'].each do |count|
          t.jsonb "#{type}_#{count}", default: []
        end
      end

      t.timestamps null: false
    end
  end
end
