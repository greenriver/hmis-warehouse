class WorkoffArbiter
  AGE_WEIGHT                  = 2
  PRIORITY_WEIGHT             = 1
  CUTOFF                      = 30
  AGE_SCALE                   = 300.0
  SPOT_CAPACITY_PROVIDER_NAME = 'spot-capacity-provider'.freeze

  def needs_worker?
    metric > CUTOFF
  end

  def add_worker!
    payload = {
      cluster: ENV.fetch('CLUSTER_NAME'),
      task_definition: ENV.fetch('WORKOFF_TASK_DEFINITION'),
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

  # Captures the increased urgency due entirely to the priority of the work
  def priority_factor(priority)
    @priorities ||= begin
      raw_priorities = Delayed::Worker.queue_attributes.values.map(&:values).flatten.sort
      range = raw_priorities.last - raw_priorities.first
      min = raw_priorities.first
      normalized_priorities = raw_priorities.map { |rp| 1 - ((rp - min).to_f / range) }

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

  define_method(:ecs) { Aws::ECS::Client.new }
end
