# frozen_string_literal: true

# __DEVOPS__

module Prometheus
  module GrMetrics
    DIRECTORY = ENV.fetch('METRICS_DIR', '/tmp/metrics')
  end
end
