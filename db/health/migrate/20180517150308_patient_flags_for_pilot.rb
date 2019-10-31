class PatientFlagsForPilot < ActiveRecord::Migration[4.2]
  def change
    add_column :patients, :pilot, :boolean, default: false, null: false
    
  end
end
