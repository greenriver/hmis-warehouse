# frozen_string_literal: true

require_relative './app'
require 'prometheus/middleware/exporter'
require 'prometheus/client/data_stores/direct_file_store'
require 'prometheus/client/gauge'
require 'prometheus/client/counter'
require 'singleton'
require_relative '../app/models/dj_metrics'

DjMetrics.instance.register_metrics_for_metrics_endpoint!

use Rack::Deflater
use Prometheus::Middleware::Exporter

run Sinatra::Application
