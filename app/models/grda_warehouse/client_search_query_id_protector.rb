# frozen_string_literal: true

module GrdaWarehouse
  class ClientSearchQueryIdProtector
    include Singleton

    def encrypt(text)
      # text should be a fingerprint digest
      raise 'Input must contain only alphanumeric characters' unless text.match?(/\A[a-zA-Z0-9]+\z/)

      encryptor = build_encryptor
      encrypted = encryptor.encrypt_and_sign(text)
      payload = encrypted
      Base64.urlsafe_encode64(payload, padding: false)
    end

    def decrypt(encrypted_text)
      decoded = Base64.urlsafe_decode64(encrypted_text)
      encrypted = decoded
      return nil unless encrypted

      encryptor = build_encryptor
      encryptor.decrypt_and_verify(encrypted)
    rescue StandardError
      nil
    end

    private

    def key
      prop_name = 'client_search/aes-128-gcm/key'
      prop = AppConfigProperty.find_by(key: prop_name)
      return prop.value if prop

      # If not found, create with upsert
      random_key = SecureRandom.random_bytes(16)
      serialized_key = Base64.strict_encode64(random_key)

      AppConfigProperty.upsert({ key: prop_name, value: serialized_key }, unique_by: :key)
      AppConfigProperty.find_by(key: prop_name).value
    end

    def build_encryptor
      key_bin = Base64.strict_decode64(key)
      ActiveSupport::MessageEncryptor.new(key_bin, cipher: 'aes-128-gcm')
    end
  end
end
