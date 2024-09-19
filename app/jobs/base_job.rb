###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BaseJob < ApplicationJob
  include NotifierConfig

  attr_accessor :start_time

  if ENV['EKS'] == 'true'
    # I can't get this to work correctly from the delayed_job initializer
    Rails.logger.info 'Bootstrapping prometheus metrics'
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
      DjMetrics.instance.dj_job_status_total_metric.increment(labels: { queue: job.queue_name, priority: job.priority, status: 'started', job_name: job.class.name })
    end

    def after_handler(job)
      DjMetrics.instance.dj_job_status_total_metric.increment(labels: { queue: job.queue_name, priority: job.priority, status: 'success', job_name: job.class.name })
      DjMetrics.instance.dj_job_run_length_seconds_metric.observe(Time.current - start_time, labels: { job_name: job.class.name })
      DjMetrics.instance.refresh_queue_sizes!
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
end
