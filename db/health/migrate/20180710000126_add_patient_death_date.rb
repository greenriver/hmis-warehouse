class AddPatientDeathDate < ActiveRecord::Migration
  def change
    add_column :epic_patients, :death_date, :date
    add_column :patients, :death_date, :date
  end
end
