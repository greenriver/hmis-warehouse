###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PublicReports
  # Geometry for an SVG line chart (points, gridlines, hit-column bounds),
  # ported from the mockup's lineChart() build-time renderer. labels/series
  # are the raw JSON-parsed shape from StateLevelHomelessness#pit_chart /
  # #inflow_outflow: labels: [String], series: [{ 'label' => String, 'values' => [Numeric] }].
  class LineChart
    WIDTH = 640
    HEIGHT = 200
    PADDING = { top: 16, right: 20, bottom: 30, left: 56 }.freeze
    DASH_PATTERNS = [nil, '7,4', '2,3', '1,4,6,4'].freeze

    attr_reader :labels, :series

    def initialize(labels:, series:)
      @labels = labels
      @series = series
    end

    def inner_width
      WIDTH - PADDING[:left] - PADDING[:right]
    end

    def inner_height
      HEIGHT - PADDING[:top] - PADDING[:bottom]
    end

    def nice_max
      @nice_max ||= begin
        max_raw = [series.flat_map { |s| s['values'] }.max.to_f, 1.0].max
        magnitude = 10**Math.log10(max_raw).floor
        (max_raw / magnitude).ceil * magnitude
      end
    end

    def step_x
      labels.size > 1 ? inner_width.to_f / (labels.size - 1) : 0.0
    end

    def x_at(index)
      PADDING[:left] + index * step_x
    end

    def y_at(value)
      PADDING[:top] + inner_height - (value.to_f / nice_max) * inner_height
    end

    def gridlines
      [0, 0.25, 0.5, 0.75, 1].map do |fraction|
        { y: (PADDING[:top] + inner_height - fraction * inner_height).round(1), value: (nice_max * fraction).round }
      end
    end

    def dash_for(series_index)
      DASH_PATTERNS[series_index % DASH_PATTERNS.size]
    end

    def points_for(values)
      values.each_with_index.map { |v, i| "#{x_at(i).round(1)},#{y_at(v).round(1)}" }.join(' ')
    end

    # One full-height hit-column per label, spanning the midpoints to its
    # neighbors (clamped to the plot edges).
    def column_bounds
      labels.each_index.map do |idx|
        center = x_at(idx)
        left_bound = idx.zero? ? PADDING[:left] : (x_at(idx - 1) + center) / 2.0
        right_bound = idx == labels.size - 1 ? WIDTH - PADDING[:right] : (center + x_at(idx + 1)) / 2.0
        { left_pct: ((left_bound / WIDTH) * 100).round(2), width_pct: (((right_bound - left_bound) / WIDTH) * 100).round(2) }
      end
    end
  end
end
