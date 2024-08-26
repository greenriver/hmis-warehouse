###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::RaceAndEthnicity
  extend ActiveSupport::Concern
  include RaceAndEthnicityCalculations

  private def race_and_ethnicity_chart_data
    {
      chart: 'race_and_ethnicity',
      config: {
        size: {
          height: node_names.count * 30,
        },
      },
      data: race_and_ethnicity_data.merge(stack: { normalize: true }),
      table: as_table(race_and_ethnicity_counts, ['Project Type'] + race_ethnicity_combinations.values),
      link_params: {
        columns: [[]] + race_ethnicity_combinations.keys.map { |k| ['details[race_ethnicity_combinations][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def race_and_ethnicity_counts
    @race_and_ethnicity_counts ||= node_names.map do |label|
      counts = race_ethnicity_combinations.values.map { |m| [m, 0] }.to_h
      # Get rid of the distinct from node_clients
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id))
      breakdowns = race_ethnicities_breakdowns(scope)
      race_ethnicity_combinations.each do |_key, value|
        counts[value] = breakdowns[value]&.count
      end
      [
        label,
        counts,
      ]
    end.to_h
  end

  private def race_and_ethnicity_data
    @race_and_ethnicity_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['groups'] = [race_ethnicity_combinations.values]
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *node_names]]

      race_ethnicity_combinations.each.with_index do |(_, race), i|
        row = [race]
        node_names.each do |label|
          row << (race_and_ethnicity_counts[label][race] || 0)
        end

        color = config.color_for('race', i)
        bg_color = color.background_color
        data['colors'][race] = bg_color
        data['labels']['colors'][race] = color.calculated_foreground_color(bg_color)
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
