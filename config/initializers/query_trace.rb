
if Rails.env.development?
  disabled = ENV['DISABLE_AR_QUERY_TRACE']
  # Rails.logger.debug "Running initializer in #{__FILE__} DISABLE_AR_QUERY_TRACE=#{disabled.inspect}"
  unless disabled
    require 'active_record_query_trace'
    ActiveRecordQueryTrace.enabled = true
  end
end
