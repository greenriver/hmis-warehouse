class FixHouseholdIDs < ActiveRecord::Migration[5.2]
  def up
    include ArelHelper
    incorrect_household_ids = GrdaWarehouse::Hud::Enrollment.
      where(original_household_id: nil).
      left_outer_joins(:exit).
      pluck(e_t[:data_source_id], e_t[:ProjectID], e_t[:HouseholdID], e_t[:EnrollmentID]).
      map do |ds_id, p_id, h_id, e_id|
        Digest::MD5.hexdigest("e_#{ds_id}_#{p_id}_#{nil}_#{e_id}")
      end

    existing = GrdaWarehouse::Hud::Enrollment.where(original_household_id: nil).distinct.pluck(:HouseholdID)
    to_fix = existing & incorrect_household_ids
    GrdaWarehouse::Hud::Enrollment.where(HouseholdID: to_fix).update_all(
      HouseholdID: nil,
      processed_as: nil,
    )
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
  end
end
