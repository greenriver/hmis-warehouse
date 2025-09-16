# frozen_string_literal: true

# __DEVOPS__

require 'prometheus/client'

module Prometheus
  module Middleware
    class Collector
      TENANT = ENV.fetch('CLIENT', 'none')
      APP = ENV.fetch('APP', 'warehouse')

      def initialize(app, registry = Prometheus::Client.registry)
        @app = app
        @registry = registry

        @http_requests_total = @registry.counter(
          :http_requests_total,
          docstring: 'Total number of HTTP requests received',
          labels: [:status, :path, :method, :rails_env, :app, :tenant],
        )

        @active_requests_gauge = @registry.gauge(
          :http_active_requests,
          docstring: 'Number of active connections to the service',
          labels: [:rails_env, :app, :tenant],
        )

        @latency_histogram = @registry.histogram(
          :http_request_duration_seconds,
          docstring: 'Duration of HTTP requests',
          labels: [:status, :path, :method, :rails_env, :app, :tenant],
        )
      end

      def call(env)
        start_time = Time.now

        # Track start of request processing
        @active_requests_gauge.increment(
          labels: { rails_env: Rails.env, app: APP, tenant: TENANT },
        )

        # Process the request
        response = @app.call(env)

        # Calculate request duration
        duration = Time.now - start_time

        # Record the request
        record_request(env, response, duration)

        # Track end of request processing
        @active_requests_gauge.decrement(
          labels: { rails_env: Rails.env, app: APP, tenant: TENANT },
        )

        # Return the response
        response
      end

      private

      def record_request(env, response, duration)
        status = response.first.to_s
        path = env['PATH_INFO']
        method = env['REQUEST_METHOD']

        @http_requests_total.increment(labels: { status: status, path: path, method: method, rails_env: Rails.env, app: APP, tenant: TENANT })
        @latency_histogram.observe(
          duration,
          labels: { status: status, path: path, method: method, rails_env: Rails.env, app: APP, tenant: TENANT },
        )
      end
    end
  end
end
