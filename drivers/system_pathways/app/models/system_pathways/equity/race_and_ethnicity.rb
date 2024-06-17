###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::RaceAndEthnicity
  extend ActiveSupport::Concern

  private def race_and_ethnicity_chart_data
    {
      chart: 'race_and_ethnicity',
      config: {
        size: {
          height: 800,
        },
      },
      data: race_and_ethnicity_data,
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
      race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [k, v] }.to_h, scope)
      race_ethnicity_combinations.each do |key, value|
        counts[value] = lookups[key]&.call(race_data)
      end
      [
        label,
        counts,
      ]
    end.to_h
  end

  private def single_race(race_data, race)
    race_data.select { |client| client[race] && !client['hispanic_latinaeo'] }.
      map { |client| client.except('id', 'hispanic_latinaeo').values }.
      count { |m| m.count(true) == 1 }
  end

  private def single_race_latinaeo(race_data, race)
    race_data.select { |client| client[race] && client['hispanic_latinaeo'] }.
      map { |client| client.except('id', 'hispanic_latinaeo').values }.
      count { |m| m.count(true) == 1 }
  end

  private def lookups
    {
      am_ind_ak_native: ->(race_data) { single_race(race_data, 'am_ind_ak_native') },
      am_ind_ak_native_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'am_ind_ak_native') },
      asian: ->(race_data) { single_race(race_data, 'asian') },
      asian_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'asian') },
      black_af_american: ->(race_data) { single_race(race_data, 'black_af_american') },
      black_af_american_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'black_af_american') },
      mid_east_n_african: ->(race_data) { single_race(race_data, 'mid_east_n_african') },
      mid_east_n_african_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'mid_east_n_african') },
      native_hi_pacific: ->(race_data) { single_race(race_data, 'native_hi_pacific') },
      native_hi_pacific_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'native_hi_pacific') },
      white: ->(race_data) { single_race(race_data, 'white') },
      white_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'white') },

      # For interdependent race information, counting is u sed to determinethe number of true values
      # recorded in a client's race hash
      hispanic_latinaeo: ->(race_data) do
        race_data.select { |client_race_hash| client_race_hash['hispanic_latinaeo'] }. # Hispanic/Latinaeo
          map { |client_race_hash| client_race_hash.except('id').values }.
          count { |m| m.count(true) == 1 } # And that is the only selected race
      end,

      multi_racial: ->(race_data) do
        race_data.reject { |client_race_hash| client_race_hash['hispanic_latinaeo'] }. # Not Hispanic/Latinaeo
          map { |client_race_hash| client_race_hash.except('id', 'hispanic_latinaeo').values }.
          count { |m| m.count(true) > 1 } # And more than one race
      end,

      multi_racial_hispanic_latinaeo: ->(race_data) do
        race_data.select { |client_race_hash| client_race_hash['hispanic_latinaeo'] }. # Hispanic/Latinaeo
          map { |client_race_hash| client_race_hash.except('id', 'hispanic_latinaeo').values }.
          count { |m| m.count(true) > 1 } # And more than one additional race
      end,

      race_none: ->(race_data) do
        race_data.map(&:values).count { |m| m.all?(false) }
      end,
    }.freeze
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
