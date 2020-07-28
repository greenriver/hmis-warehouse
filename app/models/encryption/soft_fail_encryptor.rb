module Encryption
  module SoftFailEncryptor
    extend ::Encryptor

    # if true, return '[REDACTED]' instead of throwing encryption-related
    # exceptions
    cattr_accessor :pii_soft_failure

    def self.decrypt(*args, &block)
      crypt :decrypt, *args, &block
    rescue OpenSSL::Cipher::CipherError, ArgumentError => e
      if pii_soft_failure
        Rails.logger.error '[PII] redacted PII due to decryption error. Probably an invalid key'
        '[REDACTED]'
      else
        raise e
      end
    end
  end
end
