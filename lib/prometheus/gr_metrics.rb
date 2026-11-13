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

# __DEVOPS__

module Prometheus
  module GrMetrics
    DIRECTORY = ENV.fetch('METRICS_DIR', '/tmp/metrics')
  end
end
