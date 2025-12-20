# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  # We use a thread-safe registry to track which worker is running in which thread.
  # This allows us to check if the specific worker has been signaled to stop (SIGTERM)
  # without interfering with Delayed Job's internal signal handling.
  @registry_mutex = Mutex.new
  @active_workers = {} # { thread_object_id => worker_instance }

  class << self
    attr_reader :registry_mutex

    def register_worker(worker)
      @registry_mutex.synchronize do
        # rubocop:disable Lint/HashCompareByIdentity
        @active_workers[Thread.current.object_id] = worker
        # rubocop:enable Lint/HashCompareByIdentity
      end
    end

    def unregister_worker
      @registry_mutex.synchronize do
        @active_workers.delete(Thread.current.object_id)
      end
    end

    def current_worker_stopping?
      worker = nil
      @registry_mutex.synchronize do
        # rubocop:disable Lint/HashCompareByIdentity
        worker = @active_workers[Thread.current.object_id]
        # rubocop:enable Lint/HashCompareByIdentity
      end
      # Delayed::Worker uses @exit to signal shutdown when it receives SIGTERM
      worker&.instance_variable_get(:@exit) || false
    end

    # For testing purposes
    def reset!
      @registry_mutex.synchronize do
        @active_workers = {}
      end
    end
  end

  callbacks do |lifecycle|
    lifecycle.before(:perform) do |worker, _job|
      SignalHandlerPlugin.register_worker(worker)
    end

    lifecycle.after(:perform) do |_worker, _job|
      SignalHandlerPlugin.unregister_worker
    end
  end
end

Delayed::Worker.plugins << SignalHandlerPlugin
