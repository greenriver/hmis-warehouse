###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# segments: [{ label:, value: (percent), color: }].
class PublicReports::StateDashboard::DonutChart
  CX = 21
  CY = 21
  R = 15.9155
  STROKE_WIDTH = 8
  INNER_R = R - STROKE_WIDTH / 2.0
  OUTER_R = R + STROKE_WIDTH / 2.0

  Arc = Struct.new(:label, :value, :color, :label_text, :dasharray, :dashoffset, :divider, :tooltip, keyword_init: true)

  def initialize(segments)
    @segments = segments
  end

  def arcs
    cumulative = 0
    @segments.map do |seg|
      value = seg[:value]
      label_text = "#{seg[:label]}: #{PublicReports::StateDashboard::WhoCharts.js_number(value)}%"
      arc = Arc.new(
        label: seg[:label],
        value: value,
        color: seg[:color],
        label_text: label_text,
        dasharray: "#{PublicReports::StateDashboard::WhoCharts.js_number(value)} #{PublicReports::StateDashboard::WhoCharts.js_number(100 - value)}",
        dashoffset: PublicReports::StateDashboard::WhoCharts.js_number(25 - cumulative),
        divider: divider(cumulative),
        tooltip: tooltip(label_text, cumulative + value / 2.0),
      )
      cumulative += value
      arc
    end
  end

  private def to_xy(pct, radius)
    rad = ((pct / 100.0) * 360 - 90) * (Math::PI / 180)
    [CX + radius * Math.cos(rad), CY + radius * Math.sin(rad)]
  end

  private def fixed(number)
    format('%.2f', number)
  end

  private def divider(start_pct)
    return nil unless @segments.size > 1

    x1, y1 = to_xy(start_pct, INNER_R)
    x2, y2 = to_xy(start_pct, OUTER_R)
    { x1: fixed(x1), y1: fixed(y1), x2: fixed(x2), y2: fixed(y2) }
  end

  private def tooltip(label_text, mid_pct)
    tx, ty = to_xy(mid_pct, OUTER_R + 3)
    width = [14, ERB::Util.html_escape(label_text).length * 2.1 + 3].max
    anchor = if mid_pct > 25 && mid_pct < 75 then 'middle' elsif mid_pct <= 25 then 'start' else 'end' end
    rect_x = tx - (case anchor when 'start' then 1 when 'end' then width - 1 else width / 2.0 end)
    text_x = case anchor when 'start' then tx - 1 + width / 2.0 when 'end' then tx + 1 - width / 2.0 else tx end
    { anchor: anchor, rect_x: fixed(rect_x), rect_y: fixed(ty - 2.5), width: fixed(width), text_x: fixed(text_x), text_y: fixed(ty + 0.9) }
  end
end
