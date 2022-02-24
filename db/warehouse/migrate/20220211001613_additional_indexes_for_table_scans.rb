class AdditionalIndexesForTableScans < ActiveRecord::Migration[6.1]
  def change
    remove_index :ch_enrollments, :enrollment_id
    add_index :ch_enrollments, [:enrollment_id, :chronically_homeless_at_entry], name: :ch_enrollments_e_id_ch
    add_index :ch_enrollments, [:enrollment_id, :processed_as], name: :ch_enrollments_e_id_pro
    remove_index :hmis_forms, :client_id
    add_index :hmis_forms, [:client_id, :assessment_id]
    # The following indexes are no longer relevant and just take up a ton of space
    remove_index :hmis_2020_services, :DateDeleted
    remove_index :hmis_csv_2020_services, :DateDeleted
    remove_index :hmis_2020_enrollments, :DateDeleted
    remove_index :hmis_csv_2020_enrollments, :DateDeleted
  end
end
