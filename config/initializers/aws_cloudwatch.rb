Rails.logger.debug "Running initializer in #{__FILE__}"

def find_log_stream_name
  log_group = ENV.fetch('TARGET_GROUP_NAME', nil)

  if log_group.nil?
    Rails.logger.info 'TARGET_GROUP_NAME not set, bailing out'
    return nil
  end

  begin
    task_meta = Net::HTTP.get( URI( "#{ENV['ECS_CONTAINER_METADATA_URI_V4']}/task" ) )
    task_arn  = JSON.parse(task_meta)["TaskARN"]
    task_id   = task_arn.split('/').last
  rescue StandardError => e
    Rails.logger.error 'Something broke when querying ENV for the ECS task id.'
    Rails.logger.error e.message
    return nil
  end

  return ENV.fetch('LOG_STREAM_NAME_PREFIX') + "/#{task_id}"
end

log_stream_name = find_log_stream_name
log_group_name = ENV.fetch('TARGET_GROUP_NAME', nil)

if log_stream_name.present? && log_group_name.present?
  log_stream_escaped = log_stream_name.gsub('/', '$252F')
  log_stream_link = "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#logsV2:log-groups/log-group/#{log_group_name}/log-events/#{log_stream_escaped}"

  ENV['LOG_STREAM_NAME'] = log_stream_name
  ENV['LOG_STREAM_URL'] = log_stream_link
  Rails.logger.info 'Current log stream: ' + ENV['LOG_STREAM_NAME']
end
