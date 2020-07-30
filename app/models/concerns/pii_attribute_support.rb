module PIIAttributeSupport
  extend ActiveSupport::Concern

  PIIAccessDeniedException = Class.new(StandardError)

  # Update this to the complete set of classes supporting encrypted PII
  def self.allowed_pii_class_names
    return @allowed_pii_class_names unless @allowed_pii_class_names.nil?

    @allowed_pii_class_names = [
      'GrdaWarehouse::Hud::Client',
      'GrdaWarehouse::Import::HmisTwentyTwenty::Client',
      'GrdaWarehouse::Import::HMISSixOneOne::Client',
      'Reporting::DataQualityReports::Enrollment',
      'GrdaWarehouse::ImportLog',
      'GrdaWarehouse::Upload',
      'TestPerson',
      'TestClient',
    ]
    @allowed_pii_class_names
  end

  def self.allowed_pii_classes
    allowed_pii_class_names.map(&:constantize)
  end

  def self.pii_table_names
    allowed_pii_classes.map(&:table_name)
  end

  def self.allow_all_pii!
    allowed_pii_classes.each(&:allow_pii!)
  end

  def self.deny_all_pii!
    allowed_pii_classes.each(&:deny_pii!)
  end

  # a memoized lookup by class of the columns and attr_encrypted configuration
  # used by pluck
  def self.pii_columns
    return @pii_columns unless @pii_columns.nil?

    keys = pii_table_names
    values = allowed_pii_classes.map do |klass|
      attrs = klass.encrypted_attributes.dup
      attrs.each_key do |column_name|
        attrs[column_name][:model_class] = klass
      end
      attrs
    end
    @pii_columns = Hash[keys.zip(values)]
  end

  module ClassMethods
    def current_pii_key
      @current_pii_key ||= Encryption::Secret.current.plaintext_key
    end

    def current_pii_key=(temporary_key)
      @current_pii_key = temporary_key
    end

    def forget_current_pii_key!
      @current_pii_key = nil
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
        Rails.logger.error "[PII] Didn't allow PII explicitly"
        'invalid-key'
      else
        raise PIIAccessDeniedException
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
    self.class.allow_pii!
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
    self.class.forget_current_pii_key!
  end

  included do |parent|
    if PIIAttributeSupport.allowed_pii_class_names.exclude?(parent.name)
      names = PIIAttributeSupport.allowed_pii_class_names.join(', ')
      raise "You can't include PIIAttributeSupport in #{parent} yet. It must be in this set: [#{names}]"
    end
  end
end
