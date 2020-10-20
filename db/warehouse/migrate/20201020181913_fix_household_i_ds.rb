class FixHouseholdIDs < ActiveRecord::Migration[5.2]
  def up
    incorrect_household_ids = GrdaWarehouse::Hud::Enrollment.
      where(original_household_id: nil).
      pluck(:data_source_id, :ProjectID, :HouseholdID, :EnrollmentID).
      map do |ds_id, p_id, h_id, e_id|
        Digest::MD5.hexdigest("e_#{ds_id}_#{p_id}_#{nil}_#{e_id}")
      end

    existing = GrdaWarehouse::Hud::Enrollment.where(original_household_id: nil).
      distinct.
      pluck(:HouseholdID)
    to_fix = existing & incorrect_household_ids
    GrdaWarehouse::Hud::Enrollment.where(HouseholdID: to_fix).update_all(
      HouseholdID: nil,
      original_household_id: 'cleaned',
      processed_as: nil,
    ) if to_fix.any?

    additional_cleanup = (existing - to_fix).select { |hh| hh&.length == 32 }
    household_id_exists_in_importer = HmisCsvTwentyTwenty::Importer::Enrollment.
      where(HouseholdID: additional_cleanup).select(:HouseholdID)
    GrdaWarehouse::Hud::Enrollment.where(HouseholdID: additional_cleanup).
      where.not(HouseholdID: household_id_exists_in_importer).
      update_all(
        HouseholdID: nil,
        original_household_id: 'cleaned',
        processed_as: nil,
      ) if additional_cleanup.any?

    # GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
  end
end
