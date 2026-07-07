###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# __DEVOPS__

require 'prometheus/middleware/collector'
require 'prometheus/gr_metrics'

Prometheus::Client.config.data_store =
  Prometheus::Client::DataStores::DirectFileStore.new(dir: Prometheus::GrMetrics::DIRECTORY)

# see lib/prometheus/collector.rb
Rails.application.middleware.use Prometheus::Middleware::Collector
