class IndexEnrollmentOnHouseholdId < ActiveRecord::Migration
  def change
    add_index :Enrollment, [:data_source_id, :HouseholdID, :ProjectID], name: :idx_enrollment_ds_id_hh_id_p_id
  end
end
