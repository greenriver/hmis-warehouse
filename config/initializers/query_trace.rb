if Rails.env.development? && ENV['DISABLE_AR_QUERY_TRACE'] != 'true'
  require 'active_record_query_trace'
  ActiveRecordQueryTrace.enabled = true
end
