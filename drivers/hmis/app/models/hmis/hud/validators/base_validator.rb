class Hmis::Hud::Validators::BaseValidator < ActiveModel::Validator
  def skip_all_validations?(record)
    record.skip_validations == [:all]
  end

  def skipped_attributes(record)
    record.skip_validations
  end

  def configuration
    {}
  end

  def required_fields(record)
    record.required_fields
  end

  # Override to return HmisError::Error objects
  def self.hmis_validate(_record, **_)
    []
  end

  def validate(record)
    return if skip_all_validations?(record)

    configuration.except(*skipped_attributes(record)).each do |key, options|
      required = options[:null] == false || required_fields(record).include?(key.to_sym)
      record.errors.add(key, :required) if required && missing?(key, record)
      record.errors.add(key, :invalid) if !missing?(key, record) && invalid_enum_value?(key, record)
      record.errors.add(key, :too_long, count: options[:limit]) if too_long?(key, record, options[:limit])
    end

    yield if block_given?
  end

  # Shared messages
  def self.before_entry_message(entry_date)
    "cannot be before entry date (#{entry_date.strftime('%m/%d/%Y')})"
  end

  def self.after_exit_message(exit_date)
    "cannot be after exit date (#{exit_date.strftime('%m/%d/%Y')})"
  end

  def self.future_message
    'cannot be in the future'
  end

  def self.over_thirty_days_ago_message
    'is over 30 days ago'
  end

  def self.over_twenty_years_ago_message
    'cannot be more than 20 years ago'
  end

  def self.equals_dob_message
    "is equal to the client's DOB"
  end

  def self.before_dob_message
    "cannot be before client's DOB"
  end

  def self.before_hoh_entry_message(hoh_entry_date)
    "is before the Head of Household's entry date (#{hoh_entry_date.strftime('%m/%d/%Y')})"
  end

  private

  def too_long?(key, record, limit = nil)
    limit.present? && record.send(key).present? && record.send(key).to_s.size > limit
  end

  def missing?(key, record)
    record.send(key).blank?
  end

  def invalid_enum_value?(key, record)
    record.send(key) == Types::BaseEnum::INVALID_VALUE
  end
end
