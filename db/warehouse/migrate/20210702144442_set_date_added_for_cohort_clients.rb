class SetDateAddedForCohortClients < ActiveRecord::Migration[5.2]
  def up
    PaperTrail.request(enabled: false) do # Migration can't find 'versions' table?
      GrdaWarehouse::CohortClient.find_each do |cohort_client|
        cohort_client.update(date_added_to_cohort: cohort_client.created_at.to_date)
      end
    end
  end
end
