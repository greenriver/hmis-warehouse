# frozen_string_literal: true

require 'aws-sdk-cloudwatchlogs'
require 'net/http'
require 'json'
require 'logger'

class RequestLoggerMiddleware
  @@file_logger ||= Logger.new('log/request_headers.log')

  def initialize(app)
    @app = app
    @cloudwatch_logger = setup_cloudwatch_logger
    send_log_to_file('file logger started') unless @cloudwatch_logger
  end

  def call(env)
    log_request(env)
    @app.call(env)
  end

  private

  def setup_cloudwatch_logger
    return nil if ENV['EKS'] == 'true'

    log_group_name = ENV['TARGET_GROUP_NAME']
    log_stream_name = find_log_stream_name

    return nil if log_group_name.nil? || log_stream_name.nil?

    cloudwatch_logs = Aws::CloudWatchLogs::Client.new(region: ENV['AWS_REGION'] || 'us-east-1')

    begin
      cloudwatch_logs.create_log_stream(
        log_group_name: log_group_name,
        log_stream_name: log_stream_name,
      )
    rescue Aws::CloudWatchLogs::Errors::ResourceAlreadyExistsException
      # Stream already exists, which is fine
    end

    {
      client: cloudwatch_logs,
      log_group_name: log_group_name,
      log_stream_name: log_stream_name,
    }
  end

  def find_log_stream_name
    log_group = ENV['TARGET_GROUP_NAME']
    return nil if log_group.nil?

    begin
      task_meta = Net::HTTP.get(URI("#{ENV['ECS_CONTAINER_METADATA_URI_V4']}/task"))
      task_arn  = JSON.parse(task_meta)['TaskARN']
      task_id   = task_arn.split('/').last
    rescue StandardError => e
      @@file_logger.error("Error querying ENV for the ECS task id: #{e.message}")
      return nil
    end

    ENV['LOG_STREAM_NAME_PREFIX'] + "/#{task_id}"
  end

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
    }

    if @cloudwatch_logger
      send_log_to_cloudwatch(message)
    else
      send_log_to_file(message)
    end
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

  def send_log_to_file(message)
    @@file_logger.info(message.is_a?(String) ? message : message.to_json)
  end

  def send_log_to_cloudwatch(message)
    @cloudwatch_logger[:client].put_log_events(
      log_group_name: @cloudwatch_logger[:log_group_name],
      log_stream_name: @cloudwatch_logger[:log_stream_name],
      log_events: [
        {
          timestamp: (Time.now.to_f * 1000).to_i,
          message: message.to_json,
        },
      ],
    )
  rescue Aws::CloudWatchLogs::Errors::InvalidSequenceTokenException => e
    sequence_token = e.message.match(/The next expected sequenceToken is: (\S+)/)[1]
    retry_with_sequence_token(message, sequence_token)
  end

  def retry_with_sequence_token(message, sequence_token)
    @cloudwatch_logger[:client].put_log_events(
      log_group_name: @cloudwatch_logger[:log_group_name],
      log_stream_name: @cloudwatch_logger[:log_stream_name],
      log_events: [
        {
          timestamp: (Time.now.to_f * 1000).to_i,
          message: message,
        },
      ],
      sequence_token: sequence_token,
    )
  end
end

class RequestLoggerMiddlewareRailtie < ::Rails::Railtie
  initializer 'request_logger.middleware' do |app|
    # try and get this first in the middleware stack to capture raw headers
    app.middleware.insert_before(0, RequestLoggerMiddleware)
  end
end
