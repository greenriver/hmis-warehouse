class DontRequireAgency < ActiveRecord::Migration[5.2]
  def change
    change_column_null :health_emergency_clinical_triages, :agency_id, true
    change_column_null :health_emergency_ama_restrictions, :agency_id, true
    change_column_null :health_emergency_triages, :agency_id, true
    change_column_null :health_emergency_tests, :agency_id, true
    change_column_null :health_emergency_isolations, :agency_id, true
  end
end
