class AddEmergencyType < ActiveRecord::Migration[5.2]
  def change
    add_column :health_emergency_clinical_triages, :emergency_type, :string
    add_column :health_emergency_ama_restrictions, :emergency_type, :string
    add_column :health_emergency_triages, :emergency_type, :string
    add_column :health_emergency_tests, :emergency_type, :string
    add_column :health_emergency_isolations, :emergency_type, :string
  end
end
