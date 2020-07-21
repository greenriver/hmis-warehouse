Rails.logger.debug "Running initializer in #{__FILE__}"

if Encryption::Util.new.encryption_enabled?
  Rails.logger.info "Encryption is enabled for PII"
else
  Rails.logger.info "Encryption is NOT enabled for PII"
end
