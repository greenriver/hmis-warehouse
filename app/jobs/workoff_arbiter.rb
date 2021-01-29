###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
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
class WorkoffArbiter
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
  MAX_WORKOFF_WORKERS = 10

  # This is the abstraction that provides EC2 instances as needed to run the
  # workoff job
  SPOT_CAPACITY_PROVIDER_NAME = 'spot-capacity-provider'.freeze

  def needs_worker?
    metric > CUTOFF && _current_worker_count < MAX_WORKOFF_WORKERS
  end

  def add_worker!
    payload = {
      cluster: ENV.fetch('CLUSTER_NAME'),
      task_definition: _task_definition,
      capacity_provider_strategy: [
        {
          capacity_provider: ENV.fetch('WORKOFF_CAPACITY_PROVIDER') { SPOT_CAPACITY_PROVIDER_NAME },

          weight: 1,
          base: 1,
        },
      ],
    }

    ecs.run_task(payload)
  end

  private

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
    # Get all non-failed, non-running jobs
    scope = Delayed::Job.
      select('created_at, priority, queue').
      where(failed_at: nil, locked_at: nil, locked_by: nil)

    scope.sum do |job|
      # puts  "#{job.queue} job: 1 + #{priority_factor(job.priority)} + #{age_factor(job.created_at)}"
      1 + priority_factor(job.priority) + age_factor(job.created_at)
    end
  end

  def _task_family
    _task_definition.split(%r{/}).last.split(/:/).first
  end

  def _task_definition
    ENV.fetch('WORKOFF_TASK_DEFINITION')
  end


  define_method(:ecs) { Aws::ECS::Client.new }
end
