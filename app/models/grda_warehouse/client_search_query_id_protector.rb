# frozen_string_literal: true

require 'base64'
require 'singleton'

module GrdaWarehouse
  class ClientSearchQueryIdProtector
    include Singleton
    CIPHER = 'aes-128-gcm'
    KEY_LENGTH_BYTES = 16

    def initialize
      @encryptor = build_encryptor
      super()
    end

    def encrypt(text)
      raise 'Input must be a non-empty string.' unless text.is_a?(String) && text.present?
      # text should be a fingerprint digest
      raise 'Input must contain only alphanumeric characters' unless text.match?(/\A[a-zA-Z0-9]+\z/)

      encrypted_data = @encryptor.encrypt_and_sign(text)
      Base64.urlsafe_encode64(encrypted_data, padding: false)
    end

    def decrypt(encrypted_text)
      raise 'Encrypted text must be a non-empty string.' unless encrypted_text.is_a?(String) && encrypted_text.present?

      decoded_payload = Base64.urlsafe_decode64(encrypted_text)
      @encryptor.decrypt_and_verify(decoded_payload)
    rescue Base64::ArgumentError, ActiveSupport::MessageEncryptor::InvalidMessage => e
      Sentry.capture_exception(e)
      nil
    end

    private

    def fetch_or_generate_key_material
      key_config_name = "client_search/#{CIPHER}/key"
      random_key_bytes = SecureRandom.random_bytes(KEY_LENGTH_BYTES)
      serialized_key = Base64.strict_encode64(random_key_bytes)

      AppConfigProperty.upsert({ key: key_config_name, value: serialized_key }, unique_by: :key)
      newly_stored_prop = AppConfigProperty.find_by(key: key_config_name)
      newly_stored_prop.value
    end

    def build_encryptor
      key_string_b64 = fetch_or_generate_key_material
      key_binary = Base64.strict_decode64(key_string_b64)

      ActiveSupport::MessageEncryptor.new(key_binary, cipher: CIPHER)
    end
  end
end
