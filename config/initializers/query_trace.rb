Rails.logger.info "Running initializer in #{__FILE__}"

if Rails.env == 'development'
  ActiveRecordQueryTrace.enabled = true
end
