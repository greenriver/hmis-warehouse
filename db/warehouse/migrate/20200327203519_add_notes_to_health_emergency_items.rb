class AddNotesToHealthEmergencyItems < ActiveRecord::Migration[5.2]
  def change
    add_column :health_emergency_clinical_triages, :notes, :text
    add_column :health_emergency_ama_restrictions, :notes, :text
    add_column :health_emergency_triages, :notes, :text
    add_column :health_emergency_tests, :notes, :text
    add_column :health_emergency_isolations, :notes, :text
  end
end
