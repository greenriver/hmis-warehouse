# https://github.com/prometheus/client_ruby
#
# This is run by a rails (the delayed job worker) AND by a standalone sinatra
# app exposing the metrics, so rails-dependent code should be used sparingly.

class DjMetrics
  include Singleton
  attr_reader :queues
  attr_accessor :initialized

  METRICS_DIR = ENV.fetch('METRICS_DIR', '/app/prometheus-metrics')

  def initialize
    Prometheus::Client.config.data_store = Prometheus::Client::DataStores::DirectFileStore.new(dir: METRICS_DIR)

    @queues = Set.new(['short_running', 'default_priority', 'long_running'])
  end

  def register_metrics_for_metrics_endpoint!
    self.class.instance_methods(false).each do |meth|
      next unless meth.to_s.match?(/_metric$/)

      send(meth)
    end
  end

  def metrics_ready?
    File.exist?(METRICS_DIR + '/ready')
  end

  def register_metrics_for_delayed_job_worker!
    Dir['/app/prometheus-metrics/*'].each do |file_path|
      File.unlink(file_path)
    end

    register_metrics_for_metrics_endpoint!
    refresh_queue_sizes!
    FileUtils.touch('/app/prometheus-metrics/ready')
  end

  def dj_job_status_total_metric
    @dj_job_status_total_metric ||= \
      Prometheus::Client::Counter.new(:dj_job_statuses_total, docstring: 'counter of jobs handled', labels: [:queue, :priority, :status, :job_name]).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_job_statuses_total }
      end
  end

  def dj_queue_size_metric
    @dj_queue_size_metric ||= \
      Prometheus::Client::Gauge.new(:dj_queue_size, docstring: 'total number of pending jobs in a queue', labels: [:queue]).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_queue_size }
      end
  end

  def dj_job_run_length_seconds_metric
    @dj_job_run_length_seconds_metric ||= \
      Prometheus::Client::Histogram.new(:dj_job_run_length_seconds, docstring: 'length of a job run', labels: [:job_name], buckets: run_length_buckets).tap do |metric|
        prometheus.register(metric) if prometheus.metrics.none? { |m| m.name == :dj_job_run_length_seconds }
      end
  end

  def refresh_queue_sizes!
    others = @queues.dup

    Delayed::Job.where('failed_at IS NULL').where('locked_by IS NULL').group(:queue).count.each do |queue, size|
      @queues << queue
      others.delete(queue)
      dj_queue_size_metric.set(size, labels: { queue: queue })
    end

    # These are the ones that are now empty (if any)
    others.each do |queue|
      dj_queue_size_metric.set(0, labels: { queue: queue })
    end
  end

  private

  def run_length_buckets
    Prometheus::Client::Histogram.exponential_buckets(start: 10, factor: 2, count: 15)
  end

  def prometheus
    @prometheus ||= Prometheus::Client.registry
  end
end
