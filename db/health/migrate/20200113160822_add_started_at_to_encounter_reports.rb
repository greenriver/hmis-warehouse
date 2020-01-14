class AddStartedAtToEncounterReports < ActiveRecord::Migration[5.2]
  def change
    add_column :encounter_reports, :started_at, :timestamp
  end
end
