###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Race
  extend ActiveSupport::Concern

  private def race_chart_data
    {
      chart: 'race',
      config: {
        size: {
          height: 800,
        },
      },
      data: race_data,
      table: as_table(race_counts, ['Project Type'] + races.values),
      link_params: {
        columns: [[]] + races.keys.map { |k| ['details[races][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def race_counts
    @race_counts ||= node_names.map do |label|
      counts = race_columns.values.map { |m| [m, 0] }.to_h
      # Get rid of the distinct from node_clients
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id))
      race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [sp_c_t[k], v] }.to_h, scope)
      race_columns.each do |k, race|
        counts[race] = if k == 'race_none'
          race_data.map(&:values).count { |m| m.all?(false) }
        else
          race_data.select { |r| r[sp_c_t[k]] == true }.count
        end
      end
      [
        label,
        counts,
      ]
    end.to_h
  end

  # Should look roughly like this:
  # {
  #   columns: [
  #     ['x', 'ES', 'SH', 'TH'],
  #     ['Asian', 1, 2, 3],
  #     ['White', 4, 5, 6],
  #   ],
  #   groups: [
  #     [
  #       'Asian',
  #       'White',
  #     ],
  #   ],
  #   x: 'x',
  # }
  private def race_data
    @race_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [races.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      races.each.with_index do |(_, race), i|
        row = [race]
        node_names.each do |label|
          row << (race_counts[label][race] || 0)
        end
        bg_color = config["breakdown_1_color_#{i}"]
        data['colors'][race] = bg_color
        data['labels']['colors'][race] = config.foreground_color(bg_color)
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
