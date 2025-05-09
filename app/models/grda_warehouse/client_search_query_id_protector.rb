# frozen_string_literal: true

module GrdaWarehouse
  class ClientSearchQueryIdProtector
    include Singleton

    def encrypt(text)
      # text should be a fingerprint digest
      raise "Input must contain only alphanumeric characters" unless text.match?(/\A[a-zA-Z0-9]+\z/)

      salt = random_salt
      encryptor = build_encryptor(salt)
      encrypted = encryptor.encrypt_and_sign(text)
      payload = "#{salt}:#{encrypted}"
      Base64.urlsafe_encode64(payload, padding: false)
    end

    def decrypt(encrypted_text)
      decoded = Base64.urlsafe_decode64(encrypted_text)
      salt, encrypted = decoded.split(':', 2)
      return nil unless salt && encrypted

      encryptor = build_encryptor(salt)
      encryptor.decrypt_and_verify(encrypted)
    rescue StandardError
      nil
    end

    private

    def random_salt
      SecureRandom.hex(8) # 16 chars of salt
    end

    def key
      prop = AppConfigProperty.find_by(key: 'client_search/key')
      return prop.value if prop

      # If not found, create with upsert
      random_key = SecureRandom.hex(16)
      AppConfigProperty.upsert({ key: 'client_search/key', value: random_key }, unique_by: :key)
      AppConfigProperty.find_by(key: 'client_search/key').value
    end

    def build_encryptor(salt)
      raw_key = [key].pack('H*') # Convert hex string to binary
      derived_key = OpenSSL::HMAC.digest('SHA256', raw_key, salt)[0, 16] # AES-128 requires 16 bytes
      ActiveSupport::MessageEncryptor.new(derived_key, cipher: 'aes-128-gcm')
    end
  end
end
