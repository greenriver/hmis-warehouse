# frozen_string_literal: true

class Hmis::StrictInteger < ActiveModel::Type::Integer
  def cast(value)
    return if value.nil?

    raise ArgumentError, "Invalid integer value: #{value.inspect}" if value.is_a?(String) && value !~ /\A[+-]?\d+\z/

    super
  end
end
