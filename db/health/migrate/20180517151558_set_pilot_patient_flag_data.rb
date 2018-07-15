class SetPilotPatientFlagData < ActiveRecord::Migration
  def up
    Health::Patient.update_all(pilot: true)
  end

  def down
  end
end
