Rails.logger.debug "Running initializer in #{__FILE__}"

def find_log_stream_name
  log_stream = nil
  next_token = nil
  begin
    Timeout.timeout(15) do
      log_group = ENV.fetch('TARGET_GROUP_NAME', nil)

      if log_group.nil?
        Rails.logger.info 'TARGET_GROUP_NAME not set, bailing out'
        return nil
      end

      begin
        task_meta = Net::HTTP.get( URI( "#{ENV['ECS_CONTAINER_METADATA_URI_V4']}/task" ) )
        task_arn  = JSON.parse(task_meta)["TaskARN"]
        task_id   = task_arn.split('/').last
      rescue => e
        Rails.logger.error 'Something broke when querying for the ECS task id.'
        Rails.logger.error e.message
      end

      logs ||= Aws::CloudWatchLogs::Client.new
      for i in 1..200 do # Limit to 200 requests so we're not endlessly searching.
        begin
          sleep(10) if i % 25 == 0
          response = logs.describe_log_streams({
            log_group_name: log_group,
            order_by: 'LastEventTime',
            descending: true,
            next_token: next_token,
          })
        rescue Aws::CloudWatchLogs::Errors::ThrottlingException, Timeout::Error  => e
          Rails.logger.error 'Throttling exception encountered when searching for log stream.'
          return nil
        end

        log_streams = response.log_streams
        log_stream = log_streams.find { |s| s.log_stream_name.include?(task_id) }
        if log_stream.nil?
          next_token = response.next_token
          next
        else
          return log_stream.log_stream_name
        end
      end
    end
  rescue Timeout::Error  => e
    Rails.logger.error 'Throttling exception encountered when searching for log stream.'
    return nil
  end

  if log_stream.nil?
    Rails.logger.error 'Log stream not found within 200 requests.'
    return nil
  end
end

log_stream_name = find_log_stream_name
log_group_name = ENV.fetch('TARGET_GROUP_NAME', nil)

unless log_stream_name.nil? || log_group_name.nil?
  log_stream_escaped = log_stream_name.gsub('/', '$252F')
  log_stream_link = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/#{log_group_name}/log-events/#{log_stream_escaped}"

  ENV['LOG_STREAM_NAME'] = log_stream_name
  ENV['LOG_STREAM_URL'] = log_stream_link
  Rails.logger.info 'Current log stream: ' + ENV['LOG_STREAM_NAME']
end
