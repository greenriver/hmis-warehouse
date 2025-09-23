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
  task :prune, [:action, :queue, :stale_minutes] => :environment do |_t, args|
    require 'k8s-ruby'

    # Default to "fail" so non-idempotent jobs are not silently re-run; "unlock" must be explicit
    action = (ENV['PRUNE_DJ_ACTION'] || args[:action] || 'fail').to_s.downcase
    queue  = ENV['PRUNE_DJ_QUEUE'] || args[:queue]
    stale  = (ENV['PRUNE_DJ_STALE_MINUTES'] || args[:stale_minutes]).to_i
    # Use a generous default (~31 hours) to avoid false positives across day boundaries/long jobs
    stale  = 1860 if stale <= 0

    # Extract the pod name from Delayed::Job's locked_by field; tolerate nil/malformed input
    extract_pod_name = ->(locked_by) do
      return nil if locked_by.nil?

      m = locked_by.match(/host:\s*([A-Za-z0-9.-]+)/)
      m && m[1]
    end

    # Only consider locks older than the cutoff to avoid racing with active workers
    now = Time.current
    cutoff = now - stale.minutes

    # Evaluate only currently locked, non-failed jobs; optionally narrow by queue
    scope = Delayed::Job.where.not(locked_by: nil).where(failed_at: nil)
    scope = scope.where(queue: queue) if queue.present?

    results = scope.pluck(:id, :locked_by, :locked_at)

    # Reduce Kubernetes API load by fetching live pod names once; autodetect namespace when unset
    client = K8s::Client.in_cluster_config
    ns = ENV['K8S_NAMESPACE']
    if ns.blank?
      begin
        ns = File.read('/var/run/secrets/kubernetes.io/serviceaccount/namespace').to_s.strip
      rescue StandardError
        ns = 'default'
      end
    end
    names = client.api('v1').resource('pods', namespace: ns).list.map { |p| p.metadata.name }

    # Task-scoped logging; formatting/metadata handled by Rails logger
    log = ->(msg) { Rails.logger.info("[delayed_job:prune] #{msg}") }

    acted = 0
    results.each do |id, locked_by, locked_at|
      pod = extract_pod_name.call(locked_by)
      next if pod.blank?

      # Skip if the lock belongs to a pod that still exists in the cluster
      next if names.include?(pod)

      # Do not act on fresh or unknown locks to avoid interfering with in-flight work
      next if locked_at.nil? || locked_at >= cutoff

      # Concurrency guard: match on locked_by and the exact locked_at we observed, and ensure staleness
      case action
      when 'unlock'
        affected = Delayed::Job.where(id: id, failed_at: nil, locked_by: locked_by).
          where('locked_at = ? AND locked_at < ?', locked_at, cutoff).
          update_all(locked_by: nil, locked_at: nil, run_at: now)
        acted += 1 if affected == 1
      when 'fail'
        msg = "Pruned at #{now.utc.iso8601}: pod '#{pod}' not found; locked_at=#{locked_at.utc.iso8601}"
        affected = Delayed::Job.where(id: id, failed_at: nil, locked_by: locked_by).
          where('locked_at = ? AND locked_at < ?', locked_at, cutoff).
          update_all(failed_at: now, last_error: msg)
        acted += 1 if affected == 1
      else
        # Make unsupported modes explicit so misconfiguration fails loudly
        raise ArgumentError, "action #{action.inspect} is not supported"
      end
    end

    log.call("Pruning complete processed_jobs=#{results.size} jobs_acted_on=#{acted}")
  rescue StandardError => e
    Rails.logger.error("[delayed_job:prune] #{e.class}: #{e.message}\n#{Array(e.backtrace).join("\n")}")
    exit 1
  end
end
