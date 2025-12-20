class SignalHandlerPlugin < Delayed::Plugin
  # We use a class variable or a thread-safe flag to communicate
  # between the trap context and the Ruby execution context.
  @interrupted_job_id = nil
  @previous_trap = nil

  class << self
    attr_accessor :interrupted_job_id, :previous_trap
  end

  callbacks do |lifecycle|
    lifecycle.before(:perform) do |worker, job|
      # Set up the trap and store the previous one
      SignalHandlerPlugin.previous_trap = Signal.trap('TERM') do
        SignalHandlerPlugin.interrupted_job_id = job.id
        # Tell the worker to stop after this job is done
        worker.stop

        # Call the previous handler if it was a proc
        if SignalHandlerPlugin.previous_trap.respond_to?(:call)
          SignalHandlerPlugin.previous_trap.call
        end
      end
    end

    lifecycle.after(:perform) do |_worker, _job|
      # Restore the previous trap
      if SignalHandlerPlugin.previous_trap
        Signal.trap('TERM', SignalHandlerPlugin.previous_trap)
      end

      SignalHandlerPlugin.interrupted_job_id = nil
      SignalHandlerPlugin.previous_trap = nil
    end
  end
end

Delayed::Worker.plugins << SignalHandlerPlugin
