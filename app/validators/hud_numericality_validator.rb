###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HudNumericalityValidator < ActiveModel::EachValidator
  # Why use a custom validator instead of just using Rails's built-in numericality validator?
  # Because the default validator is too strict. We allow some values which the default validator refuses, such as:
  # Integer value "500.00" -> 500
  # Decimal or integer value "500." -> 500

  INT_RGX = /\A-?\d+(\.0*)?\z/
  DEC_RGX = /\A-?(\d+(\.\d*)?|\.\d+)\z/

  def validate_each(record, attribute, _value)
    raw_value = record.read_attribute_before_type_cast(attribute) # Validate the raw value, since validations run after typecasting
    return if raw_value.nil? # Allow nils
    return if options[:integer] && (raw_value.in? [true, false]) # Allow default behavior of casting true/false to 1/0

    # Cast the value to a string and check it against the custom regex above
    regex = options[:integer] ? INT_RGX : DEC_RGX
    return if raw_value.to_s.match?(regex)

    record.errors.add(attribute, :not_a_number, message: 'is not a number')
  end
end
