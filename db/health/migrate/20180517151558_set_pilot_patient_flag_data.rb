class SetPilotPatientFlagData < ActiveRecord::Migration[4.2][4.2]
  def up
    Health::Patient.update_all(pilot: true)
  end

  def down
  end
end
