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
