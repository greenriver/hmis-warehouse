class ConvertPatientIdsToStrings < ActiveRecord::Migration
  def change
    remove_column :appointments, :patient_id, :integer
    add_column :appointments, :patient_id, :string
    remove_column :medications, :patient_id, :integer
    add_column :medications, :patient_id, :string
    remove_column :problems, :patient_id, :integer
    add_column :problems, :patient_id, :string
    remove_column :visits, :patient_id, :integer
    add_column :visits, :patient_id, :string
  end
end
