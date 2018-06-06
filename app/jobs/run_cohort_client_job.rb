class RunCohortClientJob < ActiveJob::Base

  queue_as :low_priority

  def perform(client_ids, cohort_id)
    if client_ids.present?
      client_ids.split(',').map(&:strip).compact.each do |id|
        create_cohort_client(@cohort.id, id.to_i)
      end
    elsif client_ids.present?
      create_cohort_client(@cohort.id, client_ids.to_i)
    end
  end
end
