###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Ethnicity
  extend ActiveSupport::Concern

  private def ethnicity_chart_data
    {
      chart: 'ethnicity',
      config: {
        size: {
          height: 800,
        },
      },
      data: ethnicity_data,
      table: as_table(ethnicity_counts, ['Project Type'] + ethnicities.values),
      # array for rows and array for columns to indicate which link params
      # should be attached for each
      link_params: {
        columns: [[]] + ethnicities.keys.map { |k| ['filters[ethnicities][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  private def ethnicity_data
    @ethnicity_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [ethnicities.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      ethnicities.each.with_index do |(k, ethnicity), i|
        row = [ethnicity]
        node_names.each do |label|
          count = ethnicity_counts[label][k] || 0

          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
          row << count
          data['columns'] << row
        end
        [
          ethnicity,
          data,
        ]
      end
    end
  end

  def ethnicity_counts
    @ethnicity_counts ||= node_names.map do |label|
      data = {}
      ethnicities.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(SystemPathways::Client.where(id: node_clients(label).select(:client_id)).group(:ethnicity).count)
      [
        label,
        data,
      ]
    end.to_h
  end
end
