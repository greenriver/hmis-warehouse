###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Formatting and contrast helpers for the who-section charts.
module PublicReports::StateDashboard::WhoCharts
  INK = PublicReports::Setting::INK_COLOR
  WHITE = '#ffffff'

  module_function

  def format_total(count, unit)
    return "100 or fewer #{unit}" if count.nil?

    "#{ActiveSupport::NumberHelper.number_to_delimited(count)} #{unit}"
  end

  def js_number(value)
    value.is_a?(Float) && value == value.truncate ? value.to_i.to_s : value.to_s
  end

  # NaN for a colour that isn't hex, so it gets a contrast ring and no inline label.
  def relative_luminance(hex)
    hex = hex.to_s
    hex = "##{hex[1..].chars.map { |c| c * 2 }.join}" if hex.match?(/\A#\h{3}\z/)
    return Float::NAN unless hex.match?(/\A#\h{6}\z/)

    r, g, b = [1, 3, 5].map do |i|
      c = hex[i, 2].to_i(16) / 255.0
      c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
    end
    0.2126 * r + 0.7152 * g + 0.0722 * b
  end

  def contrast_ratio(first, second)
    high, low = first >= second ? [first, second] : [second, first]
    (high + 0.05) / (low + 0.05)
  end

  def text_color(bg_hex)
    bg = relative_luminance(bg_hex)
    white = contrast_ratio(bg, relative_luminance(WHITE))
    ink = contrast_ratio(bg, relative_luminance(INK))
    white >= ink ? { color: '#fff', ratio: white } : { color: INK, ratio: ink }
  end

  def inline_label_color(value, bg_hex)
    choice = text_color(bg_hex)
    choice[:color] if value >= 8 && choice[:ratio] >= 4.5
  end

  def contrast_ring_style(bg_hex)
    ratio = contrast_ratio(relative_luminance(bg_hex), relative_luminance(WHITE))
    ratio.nan? || ratio < 3 ? 'box-shadow:inset 0 0 0 1px var(--color-ink);' : ''
  end

  def row_label(label, unit)
    unit.present? && !label.end_with?(unit) ? "#{label} #{unit}" : label
  end
end
