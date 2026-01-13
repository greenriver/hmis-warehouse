###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BaseJob < ApplicationJob
  include NotifierConfig
  include MaintenanceTaskInstrumentation

  # Priority constants for job scheduling
  # Lower numbers = higher priority (processed first)

  # 1. User Interaction Tier
  UI_IMMEDIATE_PRIORITY_NEG5 = -5 # User is actively waiting for results in the UI

  # 2. Critical System Tier
  HIGH_IMPORTANCE_PRIORITY_0 = 0 # Critical tasks needed to maintain system integrity

  # 3. Standard Operations Tier
  DEFAULT_BACKGROUND_PRIORITY_5 = 5 # Standard async tasks (default choice for most work)
  CLEANUP_BACKGROUND_PRIORITY_6 = 6 # Non-urgent cleanup following standard operations

  # 4. Batch & Bulk Tier
  PRE_BULK_PROCESSING_PRIORITY_9 = 9 # High-priority batch work that should lead the bulk queue
  BULK_PROCESSING_PRIORITY_10 = 10 # Standard bulk processing and large data exports

  # 5. Consistency & Cache Tier
  CACHE_REFRESH_PRIORITY_12 = 12 # Standard warming or rebuilding of data caches
  CLEANUP_CACHE_REFRESH_PRIORITY_13 = 13 # Non-urgent cache updates (e.g. external ID lookups)

  # 6. Maintenance Tier
  MAINTENANCE_PRIORITY_15 = 15 # Background housekeeping and eventual consistency

  attr_accessor :start_time

  if ENV['EKS'] == 'true'
    # I can't get this to work correctly from the delayed_job initializer
    Rails.logger.info 'Registering prometheus metrics for delayed jobs'
    DjMetrics.instance.register_metrics_for_delayed_job_worker!

    rescue_from StandardError do |err|
      DjMetrics.instance.dj_job_status_total_metric.increment(labels: { queue: queue_name, priority: priority, status: 'failure', job_name: self.class.name })
      raise err
    end

    # When called through Active::Job, uses this hook
    before_perform do |job|
      before_handler(job)
    end

    after_perform do |job|
      after_handler(job)
    end

    # When called through Delayed::Job, uses this hook
    def before(job)
      before_handler(job)
    end

    def after(job)
      after_handler(job)
    end

    def before_handler(job)
      self.start_time = Time.current
      DjMetrics.instance.dj_job_status_total_metric.increment(labels: { queue: job_queue_name(job), priority: job.priority, status: 'started', job_name: job.class.name })
    end

    def after_handler(job)
      DjMetrics.instance.dj_job_status_total_metric.increment(labels: { queue: job_queue_name(job), priority: job.priority, status: 'success', job_name: job.class.name })
      DjMetrics.instance.dj_job_run_length_seconds_metric.observe(Time.current - start_time, labels: { job_name: job.class.name })
      # This causes an exception related to string encoding that I couldn't figure out
      # DjMetrics.instance.refresh_queue_sizes!
    end

    # Normalize the queue name so calling the job through .perform_later and Delayed::Job.enqueue
    # are both able to determine the appropriate queue
    private def job_queue_name(job)
      return job.queue_name if job.respond_to?(:queue_name)

      job.queue
    end
  end

  if ENV['ECS'] == 'true'
    # When called through Delayed::Job, uses this hook
    def before(job)
      WorkerStatus.new(job).conditional_exit!
    end

    # When called through Active::Job, uses this hook
    before_perform do |job|
      WorkerStatus.new(job).conditional_exit!
    end
  end

  # attempts to requeue this job for a later time
  # This is somewhat brittle at this time and expects to be operating on
  # an ActiveJob instance (something like an instance of Importing::HudZip::HmisAutoMigrateJob).
  # Additionally, this expects the rails job backend to be Delayed::Job
  #
  # Postpones the current job when a "collision" is detected.
  # A collision occurs when an advisory lock cannot be acquired because another worker
  # is already processing the same data. Instead of blocking the worker or failing,
  # we clone the job and schedule it for a future time, allowing the current worker
  # to move on to other tasks.
  #
  # This creates a new Delayed::Job record that is a copy of the current one, but
  # with cleared failure metadata (failed_at, last_error) and reset attempt count,
  # ensuring it starts as a fresh attempt.
  def requeue_at(timestamp, message)
    job = delayed_job
    # It is possible for the delayed_job record to be missing (e.g. if a user deleted it
    # from the UI while the job was running). Return if we can't find the job
    unless job.present?
      Sentry.capture_message("Unable to find delayed_job for requeue_at in #{self.class.name} (AJ ID: #{job_id}, Provider ID: #{provider_job_id})")
      return
    end

    Rails.logger.info(message) if message.present?
    new_job = job.dup
    new_job.update(
      locked_at: nil,
      locked_by: nil,
      failed_at: nil,
      last_error: nil,
      run_at: timestamp,
      attempts: calculated_attempts,
    )
  end

  # Attempt to find the associated delayed job so we can use it
  def delayed_job
    # provider_job_id is the numeric ID of the Delayed::Job row
    return Delayed::Job.find_by(id: provider_job_id) if provider_job_id.present?

    # fallback to using handler
    Delayed::Job.jobs_for_class(job_id).first
  end

  # Override as necessary to limit the number of times a job is tried
  def calculated_attempts
    0
  end
end
