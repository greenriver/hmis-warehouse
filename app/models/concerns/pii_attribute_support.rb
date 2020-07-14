module PIIAttributeSupport
  extend ActiveSupport::Concern

  PIIAccessDeniedException = Class.new(StandardError)

  module ClassMethods
    def current_pii_key
      @current_pii_key ||= GrdaWarehouse::Encryption::Secret.current.plaintext_key
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
      elsif GrdaWarehouse::Encryption::SoftFailEncryptor.pii_soft_failure
        'invalid-key'
      else
        raise PIIAccessDeniedException
      end
    end

    def attr_pii(column_name)
      if GrdaWarehouse::Encryption::Util.new.encryption_enabled?
        attr_encrypted(column_name, key: :pii_encryption_key, encryptor: GrdaWarehouse::Encryption::SoftFailEncryptor)

        GrdaWarehouse::Encryption::SoftFailEncryptor.pii_soft_failure = (ENV['PII_SOFT_FAIL'] == 'true')
      else
        # A pass-through. The data is stored in the encrypted_* fields, but in
        # cleartext
        attr_encrypted(column_name, if: false)
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
