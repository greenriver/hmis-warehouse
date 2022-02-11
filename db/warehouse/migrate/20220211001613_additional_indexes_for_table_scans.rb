class AdditionalIndexesForTableScans < ActiveRecord::Migration[6.1]
  def change
    remove_index :ch_enrollments, :enrollment_id
    add_index :ch_enrollments, [:enrollment_id, :chronically_homeless_at_entry], name: :ch_enrollments_e_id_ch
    add_index :ch_enrollments, [:enrollment_id, :processed_as], name: :ch_enrollments_e_id_pro
  end
end
