class RenameAppointmentType < ActiveRecord::Migration
  def change
    rename_column :appointments, :type, :appointment_type
  end
end
