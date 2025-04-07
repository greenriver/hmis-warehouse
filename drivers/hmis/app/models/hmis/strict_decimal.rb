# frozen_string_literal: true

class Hmis::StrictDecimal < ActiveModel::Type::Decimal
  DEC_RGX = /\A-?(\d+(\.\d*)?|\.\d+)\z/

  def cast(value)
    return if value.nil?

    raise ArgumentError, "Invalid value: #{value.inspect}" unless (value.is_a? Float) || DEC_RGX.match?(value.to_s)

    super
  end
end
