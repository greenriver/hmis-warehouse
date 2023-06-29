###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::DisablingCondition
  extend ActiveSupport::Concern

  private def disabling_condition_chart_data
    {
      chart: 'disabling_condition',
      config: {
        size: {
          height: 800,
        },
      },
      data: disabling_condition_data,
      table: as_table(disabling_condition_counts, ['Project Type'] + disabling_conditions.values),
      # array for rows and array for columns to indicate which link params
      # should be attached for each
      link_params: {
        columns: [[]] + disabling_conditions.keys.map { |k| ['details[disabling_conditions][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  private def disabling_condition_data
    @disabling_condition_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [disabling_conditions.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      disabling_conditions.each.with_index do |(k, disabling_condition), i|
        row = [disabling_condition]
        node_names.each do |label|
          count = disabling_condition_counts[label][k] || 0

          color = config.color_for('disabling-condition', i)
          bg_color = color.background_color
          data['colors'][disabling_condition] = bg_color
          data['labels']['colors'][disabling_condition] = color.calculated_foreground_color(bg_color)
          row << count
        end
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end

  def disabling_condition_counts
    @disabling_condition_counts ||= node_names.map do |label|
      data = {}
      disabling_conditions.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(SystemPathways::Enrollment.where(id: node_clients(label).select(:id)).group(:disabling_condition).count)
      [
        label,
        data,
      ]
    end.to_h
  end
end
