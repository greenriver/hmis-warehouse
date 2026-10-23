###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddCohortClientsJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform(cohort_id, client_ids, user_id)
    client_ids = client_ids.split(',').map(&:strip).compact.map(&:to_i)
    cohort = cohort_source.find(cohort_id)
    cohort_client_ids = []
    # Calculate default columns for all clients at once
    defaults = cohort_source.available_columns.select(&:default_value?).to_h do |column|
      column.cohort = cohort
      [column.column, column.default_values(client_ids)]
    end
    # Add clients to cohort as quickly as possible so they show up in the UI
    client_ids.each do |id|
      cohort_client = create_cohort_client(cohort, id, user_id, defaults)
      cohort_client_ids << cohort_client.id
    end
    # calculate any cached per-client values
    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
    # calculate any cached per-cohort per-client values
    cohort.refresh_time_dependant_client_data(cohort_client_ids: cohort_client_ids)
  end

  def create_cohort_client(cohort, client_id, user_id, defaults)
    cohort_client = cohort_client_source.with_deleted.
      where(cohort_id: cohort.id, client_id: client_id).first_or_initialize
    cohort_client.deleted_at = nil
    defaults.each do |column, values|
      cohort_client[column] = values[client_id]
    end
    if cohort_client.changed? || cohort_client.new_record?
      cohort_client.save
      log_create(cohort.id, cohort_client.id, user_id)
    end
    cohort_client
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
