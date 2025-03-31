# frozen_string_literal: true

class Hmis::StrictDecimal < ActiveModel::Type::Decimal
  def cast(value)
    return if value.nil?

    raise ArgumentError, "Invalid decimal value: #{value.inspect}" if value.is_a?(String) && value !~ /\A[+-]?\d+(\.\d+)?\z/

    super
  end
end
