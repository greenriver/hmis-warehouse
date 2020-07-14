Rails.logger.debug "Running initializer in #{__FILE__}"

enabled = GrdaWarehouse::Encryption::Util.new.encryption_enabled?

if enabled
  Rails.logger.info "Encryption is enabled for PII"
else
  Rails.logger.info "Encryption is NOT enabled for PII"
end
