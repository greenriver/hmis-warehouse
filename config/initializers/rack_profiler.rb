Rails.logger.info "Running initializer in #{__FILE__}"

# frozen_string_literal: true

if Rails.env.development?
  require "rack-mini-profiler"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)
end
