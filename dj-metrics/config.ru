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

require_relative 'metrics_app'
require 'prometheus/middleware/exporter'
require 'prometheus/client/data_stores/direct_file_store'
require 'prometheus/client/gauge'
require 'prometheus/client/counter'
require 'singleton'
require_relative '../app/models/dj_metrics'

DjMetrics.instance.register_metrics_for_metrics_endpoint!

use Rack::Deflater
use Prometheus::Middleware::Exporter

run MetricsApp.freeze.app
