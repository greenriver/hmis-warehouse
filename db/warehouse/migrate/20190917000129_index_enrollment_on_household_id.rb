class IndexEnrollmentOnHouseholdId < ActiveRecord::Migration[4.2]
  def change
    add_index :Enrollment, [:data_source_id, :HouseholdID, :ProjectID], name: :idx_enrollment_ds_id_hh_id_p_id
  end
end
