###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DO NOT EDIT! The original is at:
# https://github.com/greenriver/gr-catalog/tree/main/catalog/team/npo/shared/shared_files
# This file is shared across all projects; ignore project-specific RuboCop rules
# rubocop:disable all

class DjMetrics
  include Singleton

  attr_reader :queues
  attr_accessor :initialized

  def initialize
    @queues = Set.new(['default'])
  end

  def register_metrics_for_metrics_endpoint!
    self.class.instance_methods(false).each do |meth|
      next unless meth.to_s.match?(/_metric$/)

      send(meth)
    end
    publish_pool_sizes!
    start_refresher_thread!
  end

  def publish_pool_sizes!
    workers = ENV.fetch('DJ_POOL_CONFIG', '')[/:(\d+)\s*\z/, 1] || 1
    dj_workers_total_metric.set(
      workers.to_i,
      labels: { queue_group: queue_group }
    )
  end

  def register_metrics_for_delayed_job_worker!
    Dir["#{Prometheus::GrMetrics::DIRECTORY}/*"].each do |file_path|
      next unless file_path.match?(/_#{Process.pid}.bin/) # only delete our own pid files.

      File.unlink(file_path)
    end

    register_metrics_for_metrics_endpoint!
    refresh_queue_sizes!
  end

  def dj_job_status_total_metric
    @dj_job_status_total_metric ||=
      Prometheus::Client::Counter.new(
        :dj_job_statuses_total,
        docstring: 'counter of jobs handled',
        labels: %i[queue priority status job_name]
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_job_statuses_total }
      end
  end

  def dj_queue_size_metric
    @dj_queue_size_metric ||=
      Prometheus::Client::Gauge.new(
        :dj_queue_size,
        docstring: 'total number of pending jobs in a queue',
        labels: [:queue]
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_queue_size }
      end
  end

  def dj_job_run_length_seconds_metric
    @dj_job_run_length_seconds_metric ||=
      Prometheus::Client::Histogram.new(
        :dj_job_run_length_seconds,
        docstring: 'length of a job run',
        labels: [:job_name], buckets: run_length_buckets
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_job_run_length_seconds }
      end
  end

  def dj_workers_busy_metric
    @dj_workers_busy_metric ||=
      Prometheus::Client::Gauge.new(
        :dj_workers_busy,
        docstring: 'workers currently inside invoke_job',
        labels: [:queue_group],
        store_settings: { aggregation: Prometheus::Client::DataStores::DirectFileStore::SUM }
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_workers_busy }
      end
  end

  def dj_workers_total_metric
    @dj_workers_total_metric ||=
      Prometheus::Client::Gauge.new(
        :dj_workers_total,
        docstring: 'configured worker pool size per queue group',
        labels: [:queue_group],
        store_settings: { aggregation: Prometheus::Client::DataStores::DirectFileStore::MAX }
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_workers_total }
      end
  end

  def dj_worker_loop_iterations_total_metric
    @dj_worker_loop_iterations_total_metric ||=
      Prometheus::Client::Counter.new(
        :dj_worker_loop_iterations_total,
        docstring: 'unconditional heartbeat: count of worker main-loop iterations',
        labels: [:queue_group]
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? do |m|
          m.name == :dj_worker_loop_iterations_total
        end
      end
  end

  def dj_jobs_enqueued_total_metric
    @dj_jobs_enqueued_total_metric ||=
      Prometheus::Client::Counter.new(
        :dj_jobs_enqueued_total,
        docstring: 'jobs enqueued via Delayed::Job.enqueue, recorded in the enqueueing process',
        labels: %i[queue priority job_name]
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_jobs_enqueued_total }
      end
  end

  def dj_oldest_pending_seconds_metric
    @dj_oldest_pending_seconds_metric ||=
      Prometheus::Client::Gauge.new(
        :dj_oldest_pending_seconds,
        docstring: 'age of the oldest pending job per queue, in seconds',
        labels: [:queue],
        store_settings: { aggregation: Prometheus::Client::DataStores::DirectFileStore::MAX }
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_oldest_pending_seconds }
      end
  end

  def dj_locked_jobs_metric
    @dj_locked_jobs_metric ||=
      Prometheus::Client::Gauge.new(
        :dj_locked_jobs,
        docstring: 'count of locked but unfinished jobs per queue',
        labels: [:queue],
        store_settings: { aggregation: Prometheus::Client::DataStores::DirectFileStore::MAX }
      ).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_locked_jobs }
      end
  end

  def record_invoke_job(job)
    busy_labels = { queue_group: queue_group }
    dj_workers_busy_metric.increment(by: 1, labels: busy_labels)
    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status = 'succeeded'
    begin
      yield
    rescue Exception
      status = 'errored'
      raise
    ensure
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      dj_workers_busy_metric.decrement(by: 1, labels: busy_labels)
      dj_job_run_length_seconds_metric.observe(elapsed, labels: { job_name: job_name(job) })
      dj_job_status_total_metric.increment(labels: {
                                             queue: job.queue || 'default',
                                             priority: job.priority,
                                             status: status,
                                             job_name: job_name(job),
                                           })
    end
  end

  def record_enqueue(job)
    dj_jobs_enqueued_total_metric.increment(labels: {
                                              queue: job.queue || 'default',
                                              priority: job.priority,
                                              job_name: job_name(job),
                                            })
  end

  def record_terminal_failure(job)
    dj_job_status_total_metric.increment(labels: {
                                           queue: job.queue || 'default',
                                           priority: job.priority,
                                           status: 'terminal_failure',
                                           job_name: job_name(job),
                                         })
  end

  private def job_name(job)
    payload = job.payload_object
    payload = payload.object if payload.is_a?(Delayed::PerformableMethod)
    payload.class.name
  rescue StandardError
    'unknown'
  end

  def queue_group
    Delayed::Worker.queues.first || 'default'
  end

  REFRESH_INTERVAL_SECONDS = Integer(ENV.fetch('DJ_METRICS_REFRESH_INTERVAL', 15))

  def refresh_all_gauges!
    refresh_queue_sizes!
    refresh_oldest_pending!
    refresh_locked_jobs!
  end

  def refresh_queue_sizes!
    others = @queues.dup

    Delayed::Job.where(failed_at: nil, locked_by: nil).group(:queue).count.each do |queue, size|
      @queues << queue
      others.delete(queue)
      dj_queue_size_metric.set(size, labels: { queue: queue })
    end

    # These are the ones that are now empty (if any)
    others.each do |queue|
      dj_queue_size_metric.set(0, labels: { queue: queue })
    end
  end

  def refresh_oldest_pending!
    seen = Set.new
    now = Time.current
    Delayed::Job
      .where(failed_at: nil, locked_by: nil)
      .group(:queue)
      .minimum(:run_at)
      .each do |queue, oldest_run_at|
        @queues << queue
        seen << queue
        age = [now - oldest_run_at, 0].max
        dj_oldest_pending_seconds_metric.set(age, labels: { queue: queue })
      end
    (@queues - seen).each do |queue|
      dj_oldest_pending_seconds_metric.set(0, labels: { queue: queue })
    end
  end

  def refresh_locked_jobs!
    seen = Set.new
    Delayed::Job
      .where(failed_at: nil)
      .where.not(locked_by: nil)
      .group(:queue)
      .count
      .each do |queue, count|
        @queues << queue
        seen << queue
        dj_locked_jobs_metric.set(count, labels: { queue: queue })
      end
    (@queues - seen).each do |queue|
      dj_locked_jobs_metric.set(0, labels: { queue: queue })
    end
  end

  def start_refresher_thread!
    @refresher_mutex ||= Mutex.new
    @refresher_mutex.synchronize do
      return if @refresher_started

      @refresher_started = true
    end

    Thread.new do
      Thread.current.name = 'dj-metrics-refresher'
      # The Puma exporter child inherits an AR connection pool from its parent worker.
      # Discard inherited connections so this process opens its own sockets.
      ActiveRecord::Base.connection_handler.clear_active_connections!
      loop do
        begin
          ActiveRecord::Base.connection_pool.with_connection { refresh_all_gauges! }
        rescue StandardError => e
          Rails.logger.error("[dj-metrics] refresher error: #{e.class}: #{e.message}")
        end
        sleep REFRESH_INTERVAL_SECONDS
      end
    end
  end

  private def run_length_buckets
    [0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10, 30, 60, 300, 1800, 3600, 18_000, 43_200].freeze
  end

  private def prometheus
    @prometheus ||= Prometheus::Client.registry
  end

  class Plugin < Delayed::Plugin
    FILENAME = 'prometheus-metrics/.delayed_job_metrics_started'

    callbacks do |lifecycle|
      lifecycle.before(:loop) do
        Socket.tcp('127.0.0.1', 9292, connect_timeout: 1) {}
      rescue Errno::ECONNREFUSED
        unless File.exist?(FILENAME)
          Yabeda::ActiveJob.install!
          _pid = Process.fork do
            require 'puma/cli'
            cli = Puma::CLI.new(['dj-metrics/config.ru', '--no-config', '-w', '0', '-t', '1:5', '-p',
                                 '9292'])
            cli.run
          end
          FileUtils.touch(FILENAME)
        end
      end

      lifecycle.before(:loop) do
        DjMetrics.instance.dj_worker_loop_iterations_total_metric.increment(
          labels: { queue_group: DjMetrics.instance.queue_group }
        )
      end

      lifecycle.after(:enqueue) do |job|
        DjMetrics.instance.record_enqueue(job)
      end

      lifecycle.around(:invoke_job) do |job, &block|
        DjMetrics.instance.record_invoke_job(job) { block.call(job) }
      end

      lifecycle.after(:failure) do |_worker, job|
        DjMetrics.instance.record_terminal_failure(job)
      end
    end
  end
end
