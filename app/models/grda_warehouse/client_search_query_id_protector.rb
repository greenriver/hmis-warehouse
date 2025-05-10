# frozen_string_literal: true

require 'base64'
require 'singleton'

module GrdaWarehouse
  # Handles secure encryption and decryption of client search query identifiers
  #
  # This singleton class provides encryption of database IDs to:
  # - Prevent exposing internal database IDs in URLs
  # - Ensure URLs cannot be easily guessed or manipulated
  # - Provide a secure method for retrieving search results via encrypted IDs
  #
  # It uses AES-128-GCM encryption with automatic key management and Base64 URL-safe
  # encoding for browser compatibility. The encryption key is stored in app_config_properties.
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
      # text should be a id or uuid
      raise 'Input must contain only alphanumeric characters or hyphens' unless text =~ /\A[a-z0-9-]+\z/i

      encrypted_data = @encryptor.encrypt_and_sign(text)
      Base64.urlsafe_encode64(encrypted_data, padding: false)
    end

    def decrypt(encrypted_text)
      raise 'Encrypted text must be a non-empty string.' unless encrypted_text.is_a?(String) && encrypted_text.present?

      decoded_payload = Base64.urlsafe_decode64(encrypted_text)
      @encryptor.decrypt_and_verify(decoded_payload)
    rescue StandardError => e
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
