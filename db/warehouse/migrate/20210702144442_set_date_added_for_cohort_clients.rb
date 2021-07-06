class SetDateAddedForCohortClients < ActiveRecord::Migration[5.2]
  def up
    GrdaWarehouse::CohortClient.find_each do |cohort_client|
      date_added = cohort_client.cohort_client_changes.where(change: 'create')&.last&.changed_at&.to_date || cohort_client.created_at.to_date
      cohort_client.update_columns(date_added_to_cohort: date_added)
    end
  end
end
