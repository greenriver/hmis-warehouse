# Formatting helper methods common to various claims reports

class ClaimsReporting::Formatter
  include ActionView::Helpers::NumberHelper
  def format_d(value, precision: 1)
    return if value.blank?

    too_small = precision.zero? ? 1 : 10**-precision
    value = value.to_d
    return "<#{number_with_precision too_small, precision: precision}" if value.positive? && value < too_small

    number_with_precision value, precision: precision, strip_insignificant_zeros: true, delimiter: ','
  end

  def format_i(value, precision: 0)
    format_d value, precision: precision
  end

  def format_c(value, precision: 0)
    number_to_currency value, precision: precision
  end

  def format_pct(value, precision: 1)
    too_small = 10**-precision
    return "<#{number_to_percentage too_small, precision: precision}" if value.to_d.positive? && value.to_d < too_small

    number_to_percentage value, precision: precision, strip_insignificant_zeros: true
  end
end
