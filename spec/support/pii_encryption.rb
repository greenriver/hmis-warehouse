if Encryption::Util.encryption_enabled?
  RSpec.configure do |config|
    config.before(:suite) do
      # Just ensure we have a secret, even if PII encryption is disabled
      Encryption::Secret.delete_all
      Encryption::Util.init!

      if Encryption::Secret.count != 2
        raise "You have a problem with PII encryption."
      end
    end
  end
end
