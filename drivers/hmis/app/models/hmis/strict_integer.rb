# frozen_string_literal: true

class Hmis::StrictInteger < ActiveModel::Type::Integer
  INT_RGX = /\A-?\d+(\.0+)?\z/

  def cast(value)
    return if value.nil?

    # if value is an int, it's valid
    # if value is a boolean, `super` will cast it to 0 or 1
    # if value is a string, it must match the regex, since we don't allow casting 'random string' to 0 (Rails/Postgres default behavior)
    raise ArgumentError, "Invalid value: #{value.inspect}" unless (value.is_a? Integer) || (value.in? [true, false]) || INT_RGX.match?(value.to_s)

    super
  end
end
