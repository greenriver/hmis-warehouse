###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Veteran
  extend ActiveSupport::Concern

  private def veteran_chart_data
    {
      chart: 'veteran_status',
      config: {
        size: {
          height: 800,
        },
      },
      data: veteran_status_data,
      table: as_table(veteran_status_counts, ['Project Type'] + veteran_statuses.values),
      # array for rows and array for columns to indicate which link params
      # should be attached for each
      link_params: {
        columns: [[]] + veteran_statuses.keys.map { |k| ['filters[veteran_statuses][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def veteran_status_counts
    @veteran_status_counts ||= node_names.map do |label|
      data = {}
      veteran_statuses.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(SystemPathways::Client.where(id: node_clients(label).select(:client_id)).group(:veteran_status).count)
      [
        label,
        data,
      ]
    end.to_h
  end

  private def veteran_status_data
    @veteran_status_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [veteran_statuses.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      veteran_statuses.each.with_index do |(k, veteran_status), i|
        row = [veteran_status]
        node_names.each do |label|
          count = veteran_status_counts[label][k] || 0

          bg_color = config["breakdown_4_color_#{i}"]
          data['colors'][veteran_status] = bg_color
          data['labels']['colors'][veteran_status] = config.foreground_color(bg_color)
          row << count
          data['columns'] << row
        end
        [
          veteran_status,
          data,
        ]
      end
    end
  end
end
