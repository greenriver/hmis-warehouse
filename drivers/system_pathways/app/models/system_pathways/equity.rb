###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class Equity
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        ethnicity_data
      else
        {}
      end

      data
    end

    private def ethnicity_data
      @ethnicity_data ||= {}.tap do |data|
        ethnicities = HudLists.ethnicity_map
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [ethnicities.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *node_names]]

        ethnicities.each.with_index do |(k, ethnicity), i|
          row = [ethnicity]
          node_names.each do |label|
            counts = node_clients(label).group(:ethnicity).count

            bg_color = config["breakdown_3_color_#{i}"]
            data['colors'][ethnicity] = bg_color
            data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
            row << counts[k] || 0
            data['columns'] << row
          end
          [
            ethnicity,
            data,
          ]
        end
      end
    end
  end
end
