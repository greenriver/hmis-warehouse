class RunCohortClientJob < ActiveJob::Base

  queue_as :low_priority

  def perform(cohort_id, client_ids, user_id)
    client_ids.split(',').map(&:strip).compact.each do |id|
      create_cohort_client(cohort_id, id.to_i, user_id)
    end
  end

  def create_cohort_client(cohort_id, client_id, user_id)
    @cohort = cohort_source.find(cohort_id)
    ch = cohort_client_source.with_deleted.
      where(cohort_id: cohort_id, client_id: client_id).first_or_initialize
    ch.deleted_at = nil
    cohort_source.available_columns.each do |column|
      if column.has_default_value?
        column.cohort = @cohort
        ch[column.column] = column.default_value(client_id)
      end
    end
    if ch.changed? || ch.new_record?
      ch.save
      log_create(cohort_id, ch.id, user_id)
    end
  end

  def log_create(cohort_id, cohort_client_id, user_id)
    attributes = {
      cohort_id: cohort_id,
      cohort_client_id: cohort_client_id,
      user_id: user_id,
      change: 'create',
      changed_at: Time.now,
    }      
    cohort_client_changes_source.create(attributes)
  end

  def cohort_client_changes_source
    GrdaWarehouse::CohortClientChange
  end

  def cohort_client_source
    GrdaWarehouse::CohortClient
  end

  def cohort_source
    GrdaWarehouse::Cohort
  end
end
