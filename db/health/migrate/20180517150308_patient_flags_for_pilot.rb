class PatientFlagsForPilot < ActiveRecord::Migration
  def change
    add_column :patients, :pilot, :boolean, default: false, null: false
    
  end
end
