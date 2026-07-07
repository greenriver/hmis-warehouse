###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  class << self
    def current_worker_stopping?
      worker = Thread.current[:delayed_job_worker]
      worker&.stop? || false
    end

    # Tell the worker bound to this thread to stop reserving new jobs and exit
    # after the current one. The process exits, and Kubernetes recreates the pod
    # with a freshly-rotated IRSA web-identity token.
    def stop_current_worker!(reason)
      worker = Thread.current[:delayed_job_worker]
      return unless worker

      Rails.logger.error("[delayed_job] stopping #{worker.name}: #{reason}")
      worker.stop
    end
  end

  callbacks do |lifecycle|
    # Forwards (worker, job) to the wrapped block so other around(:perform) plugins
    # (e.g. AwsCredentialPreflightPlugin) chained after this one still receive them --
    # the default identity handler only forwards whatever args it's given.
    lifecycle.around(:perform) do |worker, job, &block|
      Thread.current[:delayed_job_worker] = worker
      block&.call(worker, job)
    ensure
      Thread.current[:delayed_job_worker] = nil
    end
  end
end

# Before every delayed_job runs, verify the worker's *ambient* AWS credentials (an IRSA
# web-identity token) are actually usable. If they're not, we don't want to burn the
# job's (often limited) attempt budget on a problem that belongs to the pod, so we:
#   - reschedule the same job a few minutes out, tracked with its own safety counter in
#     the cache (independent of the job's attempts, so it survives restarts), then
#   - stop this worker so Kubernetes recycles the pod with a freshly-rotated token.
#
# Bounded: once the safety counter trips, the failure looks persistent (a misconfigured
# role/policy, not a transient token) rather than something a pod recycle will fix, so we
# stop deferring and let the job run normally -- AwsCredentialFailurePlugin below still
# catches a genuine credential error at that point and records the failure as usual.
class AwsCredentialPreflightPlugin < Delayed::Plugin
  # How many times we'll defer a job for bad credentials before giving up and letting it run.
  MAX_PREFLIGHT_RESCHEDULES = 3
  # How long to wait before retrying -- long enough for a recycled pod to get a fresh token.
  PREFLIGHT_RESCHEDULE_WAIT = 5.minutes
  # How long a credential health check result is trusted before re-checking. This check
  # runs ahead of every single job, and credential health doesn't change sub-minute, so
  # this keeps us from hammering STS on a busy queue.
  HEALTH_CHECK_TTL = 30.seconds
  # How long the deferral counter lives in the cache. Must comfortably exceed the total
  # worst-case span of MAX_PREFLIGHT_RESCHEDULES deferrals (15 minutes today) so a slow pod
  # recycle can't let the entry lapse and silently reset the counter to 0. Otherwise short,
  # so a stale entry cleans itself up shortly after the job resolves either way.
  PREFLIGHT_RESCHEDULE_CACHE_TTL = 1.hour

  class << self
    # Lets a spec that specifically exercises this plugin turn it on -- it's off by
    # default outside production/staging since AWS isn't reachable in test or development.
    attr_writer :force_enabled

    def enabled?
      return @force_enabled unless @force_enabled.nil?

      Rails.env.production? || Rails.env.staging?
    end

    def credentials_healthy?
      return true unless enabled?

      mutex.synchronize do
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        if @checked_at.nil? || (now - @checked_at) >= HEALTH_CHECK_TTL
          @healthy = check_credentials!
          @checked_at = now
        end
        @healthy
      end
    end

    # How many times this job has already been deferred for bad credentials (0 if it's
    # never been deferred). Tracked in the cache, keyed by job id, so it works for any
    # payload type -- not just ActiveJob-backed ones with a job_data hash.
    def preflight_reschedule_count(job)
      Rails.cache.read(preflight_cache_key(job)).to_i
    end

    # Release the lock and push run_at out so a fresh worker picks the job up later,
    # recording the incremented safety counter in the cache.
    def reschedule!(job, next_count)
      Rails.cache.write(preflight_cache_key(job), next_count, expires_in: PREFLIGHT_RESCHEDULE_CACHE_TTL)

      Rails.logger.info("[delayed_job] AWS credentials unhealthy; deferring job ##{job.id} (preflight #{next_count}/#{MAX_PREFLIGHT_RESCHEDULES})")
      job.update(
        locked_at: nil,
        locked_by: nil,
        run_at: Time.current + PREFLIGHT_RESCHEDULE_WAIT,
      )
    end

    private

    def preflight_cache_key(job)
      "aws_credential_preflight_reschedules:#{job.id}"
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def check_credentials!
      Aws::STS::Client.new(region: ENV.fetch('AWS_REGION', 'us-east-1')).get_caller_identity
      true
    rescue StandardError => e
      if AwsCredentialFailurePlugin.credential_failure?(e)
        Sentry.capture_message(
          'AWS credential preflight check failed',
          level: :warning,
          extra: {
            error: e.class.name,
            message: e.message,
          },
        )
        return false
      end

      # Not a credential problem we can act on (e.g. a network blip) -- fail open so an
      # unrelated hiccup in the check itself doesn't block every job in the queue.
      Sentry.capture_exception(e)
      true
    end
  end

  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, job, &block|
      if AwsCredentialPreflightPlugin.credentials_healthy?
        block.call(worker, job)
      else
        count = AwsCredentialPreflightPlugin.preflight_reschedule_count(job)
        if count >= MAX_PREFLIGHT_RESCHEDULES
          # Still bad after MAX deferrals (each spanning a pod recycle) -- this looks like a
          # misconfigured role/policy, not a rotating token, so alert an engineer and let the
          # job run normally instead of deferring forever.
          Sentry.capture_message(
            'AWS credentials still unhealthy after preflight reschedule limit; running job anyway',
            level: :error,
            extra: {
              job_id: job.id,
              preflight_reschedules: count,
            },
          )
          block.call(worker, job)
        else
          AwsCredentialPreflightPlugin.reschedule!(job, count + 1)
          SignalHandlerPlugin.stop_current_worker!('AWS credentials unhealthy (preflight)')
          # Not a job failure -- it's deferred to run later. Returning true keeps
          # Delayed::Worker#work_off's success/failure tally (and its log line) accurate.
          true
        end
      end
    end
  end
end

# When the worker's *ambient* AWS credentials go bad mid-job (rather than being caught by the
# preflight check beforehand), every job this worker reserves will fail identically and poison
# the queue. Detect that class of error and stop the worker so Kubernetes recycles the pod with
# a freshly-rotated token.
#
# We leave the job's retry budget alone: re-raising lets delayed_job reschedule normally, so a
# job with attempts remaining retries in the fresh worker and one whose budget is exhausted
# fails permanently. A job that must never retry after a credential failure is enqueued with
# its attempts already spent (e.g. max_attempts 1) -- that's an enqueue-time decision, not this
# plugin's job to enforce.
class AwsCredentialFailurePlugin < Delayed::Plugin
  # Match by name + walk the cause chain so we catch wrapped errors and don't
  # depend on AWS constants being autoloaded at initializer-load time.
  CREDENTIAL_ERROR_NAMES = [
    'Aws::STS::Errors::ExpiredTokenException',
    'Aws::STS::Errors::InvalidIdentityToken',
    'Aws::Errors::MissingCredentialsError',
  ].freeze

  def self.credential_failure?(error)
    err = error
    while err
      return true if CREDENTIAL_ERROR_NAMES.include?(err.class.name)

      err = err.cause
    end
    false
  end

  callbacks do |lifecycle|
    lifecycle.around(:invoke_job) do |job, &block|
      block.call
    rescue StandardError => e
      SignalHandlerPlugin.stop_current_worker!("AWS credential failure on job ##{job.id} (#{e.class})") if AwsCredentialFailurePlugin.credential_failure?(e)
      raise # delayed_job reschedules or fails per the job's own attempts budget
    end
  end
end

class DelayedJobJobIdProvider < Delayed::Plugin
  callbacks do |lifecycle|
    lifecycle.before(:invoke_job) do |job|
      # Expose the Delayed::Job row id to ActiveJob payloads as provider_job_id.
      payload = job.payload_object
      if payload.respond_to?(:job_data) && payload.job_data.is_a?(Hash)
        # merge (not mutate) -- job_data may be frozen
        payload.job_data = payload.job_data.merge(
          'provider_job_id' => job.id,
        )
      end
    end
  end
end

Delayed::Worker.plugins << DelayedJobJobIdProvider unless Delayed::Worker.plugins.include?(DelayedJobJobIdProvider)
Delayed::Worker.plugins << SignalHandlerPlugin unless Delayed::Worker.plugins.include?(SignalHandlerPlugin)
Delayed::Worker.plugins << AwsCredentialPreflightPlugin unless Delayed::Worker.plugins.include?(AwsCredentialPreflightPlugin)
Delayed::Worker.plugins << AwsCredentialFailurePlugin unless Delayed::Worker.plugins.include?(AwsCredentialFailurePlugin)
