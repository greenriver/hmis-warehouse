###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::InvolvesCe
  extend ActiveSupport::Concern

  private def involves_ce_chart_data
    {
      chart: 'involves_ce',
      config: {
        size: {
          height: 800,
        },
      },
      data: involves_ce_data,
      table: as_table(involves_ce_counts, ['Project Type'] + involves_ces.values),
      # array for rows and array for columns to indicate which link params
      # should be attached for each
      link_params: {
        columns: [[]] + involves_ces.keys.map { |k| ['details[involves_ce]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def involves_ce_counts
    @involves_ce_counts ||= node_names.map do |label|
      data = {}
      involves_ces.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(
        SystemPathways::Enrollment.
          joins(:client).
          where(id: node_clients(label).select(:id)).
          group(sp_c_t[:involves_ce]).count,
      )
      [
        label,
        data,
      ]
    end.to_h
  end

  private def involves_ce_data
    @involves_ce_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [involves_ces.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      involves_ces.each.with_index do |(k, involves_ce), i|
        row = [involves_ce]
        node_names.each do |label|
          count = involves_ce_counts[label][k] || 0

          bg_color = config["breakdown_4_color_#{i}"]
          data['colors'][involves_ce] = bg_color
          data['labels']['colors'][involves_ce] = config.foreground_color(bg_color)
          row << count
        end
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
