###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::Form::NumericInputValidator
  CURRENCY_RGX = /\A-?(?:[1-9]\d*|0)(?:\.\d{1,2})?\z/
  INTEGER_RGX = /\A-?(?:[1-9]\d*|0)\z/

  SPECIAL_VALUES = ['DATA_NOT_COLLECTED', '_HIDDEN'].to_set.freeze
  SUPPORTED_TYPES = ['INTEGER', 'CURRENCY'].to_set.freeze

  def call(item, value)
    return [] if value.blank? || SPECIAL_VALUES.include?(value)
    return [] unless item.type.in? SUPPORTED_TYPES

    format_errors = validate_format(item, value.to_s.strip)
    return format_errors if format_errors.any?

    validate_bounds(item, value.to_d)
  end

  private

  def validate_format(item, value)
    case item.type
    when 'INTEGER'
      INTEGER_RGX.match?(value) ? [] : ['not a valid integer']
    when 'CURRENCY'
      CURRENCY_RGX.match?(value) ? [] : ['not a valid currency amount']
    else
      []
    end
  end

  def validate_bounds(item, value)
    item.bounds.each_with_object([]) do |bound, errors|
      next unless bound.severity == 'error'

      case bound.type
      when 'MAX'
        errors << "must be less than or equal to #{bound.value_number}" if value > bound.value_number
      when 'MIN'
        errors << "must be greater than or equal to #{bound.value_number}" if value < bound.value_number
      end
    end
  end
end
