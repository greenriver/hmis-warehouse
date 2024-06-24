###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Ethnicity
  extend ActiveSupport::Concern

  private def ethnicity_chart_data
    {
      chart: 'ethnicity',
      config: {
        size: {
          height: node_names.count * 30,
        },
      },
      data: ethnicity_data.merge(stack: { normalize: true }),
      table: as_table(ethnicity_counts, ['Project Type'] + ethnicities.values),
      link_params: {
        columns: [[]] + ethnicities.keys.map { |k| ['details[ethnicities][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def ethnicity_counts
    @ethnicity_counts ||= node_names.map do |label|
      data = {}
      ethnicities.each_key do |k|
        data[k] ||= 0
      end
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id))
      hispanic_latinaeo_data = scope.pluck(:hispanic_latinaeo)
      race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [sp_c_t[k], v] }.to_h, scope)
      unknown = race_data.map(&:values).count { |m| m.all?(false) }
      data[:hispanic_latinaeo] = hispanic_latinaeo_data.count(true)
      data[:non_hispanic_latinaeo] = hispanic_latinaeo_data.count(false) - unknown
      data[:unknown] = unknown
      [
        label,
        data,
      ]
    end.to_h
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

          color = config.color_for('ethnicity', i)
          bg_color = color.background_color
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = color.calculated_foreground_color(bg_color)
          row << count
        end
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
