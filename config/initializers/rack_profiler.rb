###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Rails.logger.debug "Running initializer in #{__FILE__}"

# frozen_string_literal: true

if Rails.env.development? && ENV['RACK_MINI_PROFILER'] != 'off'
  require 'rack-mini-profiler'

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.pre_authorize_cb = lambda { |_env|
    ENV['RACK_MINI_PROFILER'] != 'off'
  }
end
