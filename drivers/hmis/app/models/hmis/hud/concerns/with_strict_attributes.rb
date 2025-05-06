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

  # ||= because of Rails reloading to avoid "constant already initialized" error
  INT_RGX ||= /\A-?\d+(\.0*)?\z/
  DEC_RGX ||= /\A-?(\d+(\.\d*)?|\.\d+)\z/

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

module Hmis::Hud::Concerns::WithStrictAttributes
  # Add validations on ALL numerical columns (int/decimal) on HUD models,
  # to prevent the default Rails/Postgres behavior of silently casting non-numeric strings to 0.

  extend ActiveSupport::Concern

  included do
    raise "#{self} cannot include Hmis::Hud::Concerns::WithStrictAttributes because the table #{table_name} does not exist. Try moving `self.table_name` assignment to the top of the class." unless table_exists?

    columns.each do |column|
      case column.type
      when :integer, :bigint
        validates column.name, hud_numericality: { integer: true }
      when :decimal, :float
        validates column.name, hud_numericality: { integer: false }
      end
    end
  end
end
