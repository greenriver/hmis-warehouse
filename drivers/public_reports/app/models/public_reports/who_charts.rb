###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PublicReports
  # Ported from charts.js / who_section.js: who_page.js re-renders these charts
  # with the JS versions on a period change, so the output must match.
  module WhoCharts
    INK = '#1B1B1B'
    WHITE = '#ffffff'

    module_function

    def format_total(count, unit)
      return "less than 100 #{unit}" if count.nil? || count < 100

      "#{ActiveSupport::NumberHelper.number_to_delimited(count)} #{unit}"
    end

    def js_number(value)
      value.is_a?(Float) && value == value.truncate ? value.to_i.to_s : value.to_s
    end

    # NaN, like charts.js, so every contrast check fails and no ring or label is drawn.
    def relative_luminance(hex)
      return Float::NAN unless hex.to_s.match?(/\A#\h{6}\z/)

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
      contrast_ratio(relative_luminance(bg_hex), relative_luminance(WHITE)) < 3 ? 'box-shadow:inset 0 0 0 1px var(--color-ink);' : ''
    end

    def row_label(label, unit)
      unit.present? && !label.end_with?(unit) ? "#{label} #{unit}" : label
    end
  end
end
