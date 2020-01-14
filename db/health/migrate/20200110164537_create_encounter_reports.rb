class CreateEncounterReports < ActiveRecord::Migration[5.2]
  def change
    create_table :encounter_reports do |t|
      t.datetime :start_date
      t.datetime :end_date
      t.references :user

      t.timestamps
    end
  end
end
