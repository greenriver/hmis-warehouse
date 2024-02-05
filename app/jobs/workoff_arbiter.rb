###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# This class computes a metric (just a number) that gets bigger the more we
# need additional job workers.
#
# Regardless of the weights below, CUTOFF is the minimum number of jobs waiting
# that will trigger a workoff job.
#
# 100 jobs waiting with a CUTOFF of 100 would trigger a workoff worker
# 50 jobs waiting with enough of them waiting a long time could trigger a workoff worker with AGE_WEIGHT set high enough
# 50 jobs waiting with a high priority could trigger a workoff worker with a PRIORITY_WEIGHT set high enough
#

require_relative '../../config/deploy/docker/lib/aws_sdk_helpers'

class WorkoffArbiter
  include AwsSdkHelpers::Helpers

  # How important is the length of time a job has been sitting around waiting?
  AGE_WEIGHT = 2

  # How important is the priority of a job that's not done?
  PRIORITY_WEIGHT = 1

  # This is the minimum value that triggers a workoff worker.
  CUTOFF = 100

  # How quickly do we ramp up to AGE_WEIGHT? a bigger number gets us to
  # AGE_WEIGHT more slowly
  AGE_SCALE = 300.0

  # How many workoff workers can we have in total
  # Once the memory analyzer is fully in production, we could track this in
  # dynamodb and make it different for each installation.
  MAX_WORKOFF_WORKERS = 6

  NOTIFICATION_THRESHOLD = 2

  def initialize
    self.class.include NotifierConfig

    setup_notifier('Workoff Worker')
  end

  def needs_worker?
    _work_pending? && _current_worker_count < MAX_WORKOFF_WORKERS
  end

  def add_worker!
    target_group_name = ENV.fetch('TARGET_GROUP_NAME', false)
    payload = {
      cluster: ENV.fetch('CLUSTER_NAME'),
      task_definition: _task_definition,
      capacity_provider_strategy: [
        {
          capacity_provider: _long_term_capacity_provider_name(target_group_name),
          weight: 1,
          base: 1,
        },
      ],
    }

    ecs.run_task(payload)
    job_count = _dj_scope.pluck(:id).count
    @notifier.ping("Added a workoff worker. Metric was #{metric.round} (#{job_count} jobs enqueued) with #{_current_worker_count} workers right now (this might include the just-created one).") if job_count > NOTIFICATION_THRESHOLD
  end

  private

  def _work_pending?
    _dj_scope.any?
  end

  def _current_worker_count
    payload = {
      cluster: ENV.fetch('CLUSTER_NAME'),
      family: _task_family,
    }

    ecs.list_tasks(payload).task_arns.length
  end

  # Captures the increased urgency due entirely to the priority of the work
  def priority_factor(priority)
    @priorities ||= begin
      # currently [-5, 0, 5], lower priorities being more important
      raw_priorities = Delayed::Worker.queue_attributes.values.map(&:values).flatten.sort

      range = raw_priorities.last - raw_priorities.first
      min = raw_priorities.first

      # [1, 2, 3]
      normalized_priorities = raw_priorities.map { |rp| 1 - ((rp - min).to_f / range) }

      # { -5 => 1, ... }
      raw_priorities.zip(normalized_priorities).to_h.tap do |p|
        p.default = 0.5
        Rails.logger.debug "Queue attributes: #{Delayed::Worker.queue_attributes}"
        Rails.logger.debug "Normalized priority values (lower priority values are more important.): #{p.inspect}"
      end
    end

    PRIORITY_WEIGHT * @priorities[priority]
  end

  # Captures the increased urgency the longer a job doesn't get done
  # The longer jobs wait, the more this approaches AGE_WEIGHT
  # The lower AGE_SCALE, the faster we approach AGE_WEIGHT per second waited
  def age_factor(timestamp)
    @now ||= Time.now
    waiting_sec = @now - timestamp
    AGE_WEIGHT * Math.tanh(waiting_sec / AGE_SCALE)
  end

  def metric
    @metric ||= _dj_scope.sum do |job|
      # puts  "#{job.queue} job: 1 + #{priority_factor(job.priority)} + #{age_factor(job.created_at)}"
      1 + priority_factor(job.priority) + age_factor(job.created_at)
    end
  end

  # Get all non-failed, non-running jobs
  # nightly-processing jobs have no queue as of this writing.
  def _dj_scope
    Delayed::Job.
      select('created_at, priority, queue').
      where(failed_at: nil, locked_at: nil, locked_by: nil).
      where("queue != 'mailers' OR queue IS NULL") # never boot a workoff worker just for mail
  end

  def _task_family
    _task_definition.split(/\//).last.split(/:/).first
  end

  def _default_capacity_provider_strategy
    cluster_name = ENV.fetch('CLUSTER_NAME')
    our_cluster = ecs.describe_clusters(clusters: [cluster_name]).clusters.first
    our_cluster.default_capacity_provider_strategy.map(&:to_h)
  end

  def _task_definition
    ENV.fetch('WORKOFF_TASK_DEFINITION')
  end
end
