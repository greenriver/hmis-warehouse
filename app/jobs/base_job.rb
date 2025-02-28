###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

class BaseJob < ApplicationJob
  include NotifierConfig

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
  def requeue_at(timestamp, message)
    Rails.logger.info(message) if message.present?
    new_job = delayed_job.dup
    new_job.update(
      locked_at: nil,
      locked_by: nil,
      run_at: timestamp,
      attempts: calculated_attempts,
    )
  end

  # Attempt to find the associated delayed job so we can use it
  def delayed_job
    job = Delayed::Job.jobs_for_class(job_id).first
    # NOTE: job_id will probably be a UUID in the handler of the row
    raise "Unable to find a related delayed job (ID: #{job_id})" unless job.present?

    job
  end

  # Override as necessary to limit the number of times a job is tried
  def calculated_attempts
    0
  end
end
