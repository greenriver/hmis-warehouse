class AddPatientToServicesAndEquipment < ActiveRecord::Migration
  def change
    add_reference :services, :patient
    add_reference :equipment, :patient
  end
end
