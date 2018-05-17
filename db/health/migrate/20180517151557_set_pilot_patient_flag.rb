class SetPilotPatientFlag < ActiveRecord::Migration
  def change
    # Convert all current patients to pilot pattients
    Health::Patient.update_all(pilot: true)
  end
end
