module PIIAttributeSupport
  extend ActiveSupport::Concern

  PIIAccessDeniedException = Class.new(StandardError)

  module ClassMethods
    def current_pii_key
      @current_pii_key ||= Encryption::Secret.current.plaintext_key
    end

    def current_pii_key=(temporary_key)
      @current_pii_key = temporary_key
    end

    # Call in controller before_action
    def deny_pii!
      @allow_pii = false
    end

    # Call in controller when you know they're allowed
    def allow_pii!
      @allow_pii = true
    end

    def allow_pii?
      @allow_pii
    end

    def pii_encryption_key
      if allow_pii?
        current_pii_key
      elsif Encryption::SoftFailEncryptor.pii_soft_failure
        'invalid-key'
      else
        raise PIIAccessDeniedException
      end
    end

    #def encrypt(encoded_cipher_text, encoded_iv)
    #    if allow_pii?
    #      cipher_text = Base64.decode64(encoded_cipher_text)
    #      iv = Base64.decode64(encoded_iv)
    #      Encryption::SoftFailEncryptor.decrypt(value: cipher_text, key: pii_encryption_key, iv: iv)
    #    else
    #      '[REDACTED]'
    #    end
    #  end

    def pluck(*args)
      # without encryption, just do the normal thing
      super(*args) unless Encryption::Util.encryption_enabled?

      original_request = Array(args).flatten.map(&:to_sym)

      decrypter = ->(encoded_cipher_text, encoded_iv) do
        if allow_pii?
          cipher_text = Base64.decode64(encoded_cipher_text)
          iv = Base64.decode64(encoded_iv)
          Encryption::SoftFailEncryptor.decrypt(value: cipher_text, key: pii_encryption_key, iv: iv)
        else
          '[REDACTED]'
        end
      end

      # Build actual request with the procs needed to extract the value we need
      # e.g. [:FirstName, :email] would become [:encrypted_FirstName, :encrypted_FirstName_iv, :email]
      transformers = []
      actual_request = original_request.flat_map do |column|
        if column.in?(encrypted_attributes.keys)
          transformers << decrypter
          [
            encrypted_attributes.dig(column, :attribute),
            "#{encrypted_attributes.dig(column, :attribute)}_iv".to_sym,
          ]
        else
          transformers << ->(x) { x }
          column
        end
      end

      # This will included base64 encoded encrypted value and base64 encoded iv potentially.
      raw_response = super(*actual_request)

      response = raw_response.map do |record|
        i = 0
        transformers.map do |func|
          # the no-op proc take one argument and returns itself (e.g. ['hello@example.com'] -> 'hello@example.com')
          # the decryption proc takes two arguments and returns the cleartext value
          #    (e.g. ['b0xuGX8Df/g3pBYU7yj1BSgi0ao=', 'N12CmX0LkO3YQhLE'] -> 'John')
          args = Array(record)[i,func.arity]

          # This proc "consumed" this many of the raw results in the record.
          # 1 or 2 in practice
          i += func.arity

          # Transform it
          func.call(*args)
        end
      end

      # requesting one column just returns all the values in a 1D array
      # requesting two or more columns returns an array of arrays of values
      # e.g. pluck(:name) -> ['Ted', 'Bill', 'Sam']
      # e.g. pluck(:name, :age) -> [['Ted', 14], ['Bill', 18], ['Sam', 42]]
      if original_request.length == 1
        response.flatten
      else
        response
      end
    end

    def attr_pii(column_name)
      if Encryption::Util.encryption_enabled?
        attr_encrypted(column_name, key: :pii_encryption_key, encryptor: Encryption::SoftFailEncryptor)

        Encryption::SoftFailEncryptor.pii_soft_failure = (ENV['PII_SOFT_FAIL'] == 'true')
      else
        Rails.logger.info "Not encrypting #{column_name}"
      end
    end
  end

  def pii_encryption_key
    self.class.pii_encryption_key
  end

  # attr_encrypted was passed either the old or new key depending on when those
  # classes loaded, so best to be explicit about which keys
  def rekey!(old_key = self.class.prev_key, new_key = self.class.key)
    encrypted_attributes.each do |attribute, params|
      encoded_value = send(params[:attribute])

      next if encoded_value.blank?

      self.class.current_pii_key = old_key
      old_value = send(attribute)

      self.class.current_pii_key = new_key
      send("#{attribute}=", old_value)
    end

    save!
  ensure
    self.class.current_pii_key = nil
  end
end
