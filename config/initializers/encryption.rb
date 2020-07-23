Rails.logger.debug "Running initializer in #{__FILE__}"

if Encryption::Util.encryption_enabled?
  Rails.logger.info "[PII] Encryption is enabled for PII"

else
  Rails.logger.info "[PII] Encryption is NOT enabled for PII"
end
