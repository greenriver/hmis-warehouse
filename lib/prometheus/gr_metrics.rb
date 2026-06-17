###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# __DEVOPS__

module Prometheus
  module GrMetrics
    DIRECTORY = ENV.fetch('METRICS_DIR', '/tmp/metrics')
  end
end
