class AddCompletedAtToEncounterReport < ActiveRecord::Migration[5.2]
  def change
    add_column :encounter_reports, :completed_at, :timestamp
  end
end
