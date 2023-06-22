###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Chronic
  extend ActiveSupport::Concern

  private def chronic_at_entry_chart_data
    {
      chart: 'chronic_at_entry',
      config: {
        size: {
          height: 800,
        },
      },
      data: chronic_at_entry_data,
      table: as_table(chronic_at_entry_counts, ['Project Type'] + chronic_at_entries.values),
      # array for rows and array for columns to indicate which link params
      # should be attached for each
      link_params: {
        columns: [[]] + chronic_at_entries.keys.map { |k| ['details[chronic_at_entries][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def chronic_at_entry_counts
    @chronic_at_entry_counts ||= node_names.map do |label|
      data = {}
      chronic_at_entries.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(SystemPathways::Enrollment.where(id: node_clients(label).select(:id)).group(:chronic_at_entry).count)
      [
        label,
        data,
      ]
    end.to_h
  end

  private def chronic_at_entry_data
    @chronic_at_entry_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [chronic_at_entries.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      chronic_at_entries.each.with_index do |(k, chronic_at_entry), i|
        row = [chronic_at_entry]
        node_names.each do |label|
          count = chronic_at_entry_counts[label][k] || 0

          bg_color = config["breakdown_4_color_#{i}"]
          data['colors'][chronic_at_entry] = bg_color
          data['labels']['colors'][chronic_at_entry] = config.foreground_color(bg_color)
          row << count
        end
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
