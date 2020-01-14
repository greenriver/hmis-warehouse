class RenameAppointmentType < ActiveRecord::Migration[4.2][4.2]
  def change
    rename_column :appointments, :type, :appointment_type
  end
end
