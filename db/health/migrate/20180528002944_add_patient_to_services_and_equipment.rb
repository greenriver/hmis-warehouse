class AddPatientToServicesAndEquipment < ActiveRecord::Migration[4.2][4.2]
  def change
    add_reference :services, :patient
    add_reference :equipment, :patient
  end
end
