# frozen_string_literal: true

class SignalHandlerPlugin < Delayed::Plugin
  class Registry < ActiveSupport::CurrentAttributes
    attribute :worker
  end

  class << self
    def current_worker_stopping?
      Registry.worker&.stop? || false
    end
  end

  callbacks do |lifecycle|
    lifecycle.around(:perform) do |worker, _job, &block|
      Registry.worker = worker
      block&.call
    ensure
      Registry.reset
    end
  end
end

Delayed::Worker.plugins << SignalHandlerPlugin unless Delayed::Worker.plugins.include?(SignalHandlerPlugin)
