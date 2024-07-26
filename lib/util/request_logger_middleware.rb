# frozen_string_literal: true

require 'net/http'
require 'json'
require 'logger'

class RequestLoggerMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    log_request(env)
    @app.call(env)
  end

  private

  def log_request(env)
    request_info = {
      request_method: env['REQUEST_METHOD'],
      path_info: env['PATH_INFO'],
      query_string: env['QUERY_STRING'],
      remote_addr: env['REMOTE_ADDR'],
      request_time: Time.now,
    }

    message = {
      request_info: request_info,
      headers: extract_headers(env),
    }.to_json

    Rails.logger.info(message)
  end

  SENSITIVE_HEADERS = [
    'HTTP_AUTHORIZATION',
    'HTTP_COOKIE',
    'HTTP_X_CSRF_TOKEN',
    'HTTP_X_API_KEY',
  ].to_set.freeze

  def extract_headers(env)
    env.select { |header, _| header.start_with?('HTTP_') }.
      map { |header, value| { header: header, value: SENSITIVE_HEADERS.include?(header) ? '[REDACTED]' : value } }
  end
end

class RequestLoggerMiddlewareRailtie < ::Rails::Railtie
  initializer 'request_logger.middleware' do |app|
    # try and get this first in the middleware stack to capture raw headers
    app.middleware.insert_before(0, RequestLoggerMiddleware)
  end
end
