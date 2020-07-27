Rails.logger.debug "Running initializer in #{__FILE__}"

if Encryption::Util.encryption_enabled?
  Rails.logger.info "[PII] Encryption is enabled for PII"
  load "lib/encrypted_pluck/monkey_patch.rb"
else
  Rails.logger.info "[PII] Encryption is NOT enabled for PII"
end
