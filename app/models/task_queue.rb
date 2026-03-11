###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Used to enqueue tasks that should be run once.
# The pattern is something like:
#
# Initializer - inject class into a list
# iterate over the list in the cron job
# If there is a record for that class in the table with no queued_at, then queue a job (and mark it queued)
# To re-run a task, insert a new row with a blank queued_at value
class TaskQueue < ApplicationRecord
  # Marking something as inactive indicates that it should be re-queued
  scope :active, -> do
    where(active: true)
  end

  scope :queued, -> do
    where(queued_at: nil)
  end

  # The expectation is that if the task is in available_tasks, then it should be in the queue
  def self.queue_unprocessed!
    done = active.pluck(:task_key, :queued_at).to_h
    available_tasks.each_key do |task_key|
      next if done[task_key.to_s].present?

      t = TaskQueue.create(task_key: task_key)
      t.delay(queue: ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)).run!
      t.update(queued_at: Time.current, active: true)
    end
  end

  def self.available_tasks
    Rails.application.config.queued_tasks
  end

  def run!
    to_run = self.class.available_tasks[task_key.to_sym]
    if to_run.blank?
      # Re-queue the task, it's possible we are just running on old code
      update(queued_at: nil)
      # But also notify that we had a potentially serious problem
      raise "Unknown task key: #{task_key}"
    end

    update(started_at: Time.current)
    to_run.call
    update(completed_at: Time.current)
  end

  # Register all one-time tasks that should be queued
  def self.register_tasks(config)
    # Fix for chronic calculator
    # Previously, imported data where the enrollment was in a literally homeless project
    # where the client would accumulate days between entry & exit that counted toward
    # "Chronically Homeless at start", the current date was used to make the chronic
    # determination instead of the exit date
    config.queued_tasks[:ch_enrollment_exited_rebuild] = -> do
      # Invalidate the calculation for any enrollment with an exit date
      # that was previously marked chronic at entry
      GrdaWarehouse::ChEnrollment.
        joins(enrollment: :exit).
        where(chronically_homeless_at_entry: true).
        update_all(processed_as: nil)
      GrdaWarehouse::ChEnrollment.maintain!
    end

    # Force a one time rebuild of destination clients to incorporate changes to ClientCleanup
    config.queued_tasks[:client_cleanup_veteran_details] = -> do
      GrdaWarehouse::Hud::Client.destination.pluck_in_batches(
        :id,
        batch_size: 10_000,
      ) do |batch|
        GrdaWarehouse::Tasks::ClientCleanup.new(destination_ids: batch).run!
      end
    end

    # Migrate from collections.coc_codes JSON column to using GrdaWarehouse::Lookups::CocCode
    config.queued_tasks[:migrate_collection_coc_codes] = -> do
      ::Collection.migrate_from_local_coc_codes
    end

    # Initial setup of HUD item lists
    config.queued_tasks[:initialize_hud_list_items_table] = -> do
      GrdaWarehouse::HudListItem.maintain!
    end

    # Migrate existing user notification preferences to alert subscriptions
    config.queued_tasks[:migrate_user_notification_preferences] = -> do
      GrdaWarehouse::AlertDefinition.maintain!
      GrdaWarehouse::ContactAlertSubscription.migrate_user_notification_preferences!
    end

    # FIX for service history services change
    config.queued_tasks[:service_history_services_materialized_rebuild_and_process] = -> do
      GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts
    end

    # Green River staff account report for tech-ops (Slack notification)
    config.queued_tasks[:gr_staff_report_q1_2026] = -> do
      GrdaWarehouse::Tasks::GrStaffReport.run!
    end
  end
end
