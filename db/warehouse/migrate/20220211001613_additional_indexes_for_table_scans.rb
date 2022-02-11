class AdditionalIndexesForTableScans < ActiveRecord::Migration[6.1]
  def change
    remove_index :ch_enrollments, :enrollment_id
    add_index :ch_enrollments, [:enrollment_id, :chronically_homeless_at_entry], name: :ch_enrollments_e_id_ch
    add_index :ch_enrollments, [:enrollment_id, :processed_as], name: :ch_enrollments_e_id_pro
    remove_index :hmis_forms, :client_id
    add_index :hmis_forms, [:client_id, :assessment_id]
    # add_index :hmis_forms, :vispdat_total_score, where: 'NULL'
    # add_index :hmis_forms, :vispdat_pregnant, where: 'NULL'
    # add_index :hmis_forms, :vispdat_physical_disability_answer, where: 'NULL'
    # add_index :hmis_forms, :housing_status, where: 'NULL'
    # add_index :hmis_forms, :pathways_updated_at, where: 'NULL'
    # add_index :hmis_forms, :covid_impact_updated_at, where: 'NULL'
  end
end
