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

  def validate(record)
    return if skip_all_validations?(record)

    configuration.except(*skipped_attributes(record)).each do |key, options|
      record.errors.add(key, :required) if missing?(key, record, options[:null])
      record.errors.add(key, :too_long, count: options[:limit]) if too_long?(key, record, options[:limit])
    end

    yield if block_given?
  end

  private

  def too_long?(key, record, limit = nil)
    limit.present? && record.send(key).present? && record.send(key).size > limit
  end

  def missing?(key, record, null = nil)
    null == false && record.send(key).blank?
  end
end
