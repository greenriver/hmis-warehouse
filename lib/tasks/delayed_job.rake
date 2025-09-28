# frozen_string_literal: true

# delayed_job:prune
#
# External invocation:
# - Triggered by Kubernetes initContainer and CronJob in `argocd-manifests`
# - Manifests: `kustomize/base/delayed-jobs-v2/components/clean-dj-v2/*`
# - Do NOT rename or change the interface without coordinating changes there
#
# Inputs (env):
# - K8S_NAMESPACE: namespace for in-cluster pod listing
# - PRUNE_DJ_ACTION: 'fail' (default) or 'unlock'
# - PRUNE_DJ_QUEUE: optional queue filter
# - PRUNE_DJ_STALE_MINUTES: integer; default 1860 (31h)
#
namespace :delayed_job do
  desc 'Prune stale Delayed::Job locks held by non-existent pods'
  task :prune, [:action, :queue, :stale_minutes] => :environment do |task, args|
    require 'k8s-ruby'

    # Default to "fail" so non-idempotent jobs are not silently re-run; "unlock" must be explicit
    action = (ENV['PRUNE_DJ_ACTION'] || args[:action] || 'fail').to_s.downcase
    queue  = ENV['PRUNE_DJ_QUEUE'] || args[:queue]
    stale  = (ENV['PRUNE_DJ_STALE_MINUTES'] || args[:stale_minutes]).to_i
    # Use a generous default (~31 hours) to avoid false positives across day boundaries/long jobs
    stale  = 1860 if stale <= 0

    # Validate action early; report to Sentry and exit on invalid input
    valid_actions = ['fail', 'unlock']
    unless valid_actions.include?(action)
      Sentry.capture_message(
        "[#{task.name}] Unsupported action #{action.inspect}; allowed: #{valid_actions.join(', ')}",
        level: :error,
      )
      exit(1)
    end

    # Extract the pod name from Delayed::Job's locked_by field; tolerate nil/malformed input
    extract_pod_name = ->(locked_by) do
      m = locked_by.to_s.match(/host:\s*([A-Za-z0-9.-]+)/)
      m && m[1]
    end

    # Only consider locks older than the cutoff to avoid racing with active workers
    now = Time.current
    cutoff = now - stale.minutes

    # Evaluate only currently locked, non-failed, stale jobs; optionally narrow by queue
    scope = Delayed::Job.where.not(locked_by: nil).where(failed_at: nil)
    scope = scope.where(queue: queue) if queue.present?
    scope = scope.where(locked_at: ...cutoff)

    candidates = scope.pluck(:id, :locked_by, :locked_at)

    # Fetching live pod names once; autodetect namespace when unset
    client = K8s::Client.in_cluster_config
    ns = ENV['K8S_NAMESPACE']
    ns ||= File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace').to_s.strip
    names = client.api('v1').resource('pods', namespace: ns).list.map { |p| p.metadata.name }

    # Task-scoped logging; formatting/metadata handled by Rails logger
    log = ->(msg) { Rails.logger.info("[#{task.name}] #{msg}") }
    log.call("Attempting prune ns=#{ns} action=#{action} queue=#{queue.presence || '*'} stale_minutes=#{stale}")

    lock_acquired = false
    Delayed::Job.with_advisory_lock(task.name, timeout_seconds: 0) do
      lock_acquired = true

      log.call("Starting prune ns=#{ns} action=#{action} queue=#{queue.presence || '*'} stale_minutes=#{stale}")

      acted = 0
      candidates.each do |id, locked_by, locked_at|
        pod = extract_pod_name.call(locked_by)
        if pod.blank?
          log.call("Could not determine pod for #{locked_by.inspect}")
          next
        end

        # Skip if the lock belongs to a pod that still exists in the cluster
        next if names.include?(pod)

        # Concurrency guard: match on locked_by and the exact locked_at we observed, and ensure staleness
        base = Delayed::Job.where(id: id, failed_at: nil, locked_by: locked_by).
          where(locked_at: locked_at).
          where(locked_at: ...cutoff)

        affected = 0
        case action
        when 'unlock'
          affected = base.update_all(locked_by: nil, locked_at: nil, run_at: now)
        when 'fail'
          msg = "Pruned at #{now.utc.iso8601}: pod '#{pod}' not found; locked_at=#{locked_at&.utc&.iso8601}"
          affected = base.update_all(failed_at: now, last_error: msg)
        end
        acted += affected
      end

      log.call("Pruning complete ns=#{ns} action=#{action} queue=#{queue.presence || '*'} processed_jobs=#{candidates.size} jobs_acted_on=#{acted}")
    end

    unless lock_acquired
      msg = "Execution skipped; advisory lock '#{task.name}' is already held"
      Sentry.capture_message(msg, level: :error)
      exit(1)
    end
  end
end
