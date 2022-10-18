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
      nullable = options[:null] || !required_fields(record).include?(key.to_sym)
      record.errors.add(key, :required) if missing?(key, record, nullable)
      record.errors.add(key, :too_long, count: options[:limit]) if too_long?(key, record, options[:limit])
    end

    yield if block_given?
  end

  private

  def too_long?(key, record, limit = nil)
    limit.present? && record.send(key).present? && record.send(key).to_s.size > limit
  end

  def missing?(key, record, nullable = nil)
    nullable == false && record.send(key).blank?
  end
end
