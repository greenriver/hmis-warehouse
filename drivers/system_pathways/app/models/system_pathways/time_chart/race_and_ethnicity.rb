###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::RaceAndEthnicity
  extend ActiveSupport::Concern

  private def race_and_ethnicity_chart_data
    {
      chart: 'race_and_ethnicity',
      config: {
        size: {
          height: project_type_node_names.count * race_ethnicity_combinations.count * 30,
        },
      },
      data: race_and_ethnicity_data,
      table: as_table(race_and_ethnicity_table_data, ['Project Type'] + race_ethnicity_combinations.values),
      link_params: {
        columns: [[]] + race_ethnicity_combinations.keys.map { |k| ['details[race_ethnicity_combinations][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def race_and_ethnicity_table_data
    race_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = race_and_ethnicity_counts[:project_type_counts].merge(race_and_ethnicity_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = race_and_ethnicity_counts[:return_counts]
    flat_counts
  end

  private def race_and_ethnicity_counts
    @race_and_ethnicity_counts ||= {}.tap do |e_counts|
      project_type_counts = project_type_node_names.map do |label|
        counts = {}
        race_ethnicity_combinations.each_value do |k|
          counts[k] ||= 0
        end
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:stay_length]
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id))
        # race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Stay Length'), scope)
        race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Stay Length'), scope)
        race_ethnicity_combinations.each do |key, value|
          data = lookups[key]&.call(race_data, stay_length_col)
          counts[value] = average(data.sum, data.count).round
        end
        [
          label,
          counts,
        ]
      end.to_h
      e_counts[:project_type_counts] = project_type_counts

      ph_counts = ph_projects.map do |p_type, p_label|
        counts = {}
        race_ethnicity_combinations.each_value do |k|
          counts[k] ||= 0
        end
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:days_to_move_in]
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(p_type).select(:id)).where(stay_length_col.not_eq(nil))
        race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Move-In'), scope)
        race_ethnicity_combinations.each do |key, value|
          data = lookups[key]&.call(race_data, stay_length_col)
          counts[value] = average(data.sum, data.count).round
        end
        [
          p_label,
          counts,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_counts

      label = 'Served by Homeless System'
      counts = {}
      race_ethnicity_combinations.each_value do |k|
        counts[k] ||= 0
      end
      # Get rid of the distinct from node_clients
      stay_length_col = sp_c_t[:days_to_return]
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id)).where(stay_length_col.not_eq(nil))
      race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Return'), scope)
      race_ethnicity_combinations.each do |key, value|
        data = lookups[key]&.call(race_data, stay_length_col)
        counts[value] = average(data.sum, data.count).round
      end
      [
        label,
        counts,
      ]
      e_counts[:return_counts] = counts
    end
  end

  private def single_race(race_data, race, stay_length_col)
    race_data.select { |client| client[sp_c_t[race]] && !client[sp_c_t['hispanic_latinaeo']] }.
      select { |client| client.except(sp_c_t['id'], sp_c_t['hispanic_latinaeo'], stay_length_col).values.count(true) == 1 }.
      map { |client| client[stay_length_col] }
  end

  private def single_race_latinaeo(race_data, race, stay_length_col)
    race_data.select { |client| client[sp_c_t[race]] && client[sp_c_t['hispanic_latinaeo']] }.
      select { |client| client.except(sp_c_t['id'], sp_c_t['hispanic_latinaeo']).values.count(true) == 1 }.
      map { |client| client[stay_length_col] }
  end

  private def lookups
    {
      am_ind_ak_native: ->(race_data, stay_length_col) { single_race(race_data, 'am_ind_ak_native', stay_length_col) },
      am_ind_ak_native_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'am_ind_ak_native', stay_length_col) },
      asian: ->(race_data, stay_length_col) { single_race(race_data, 'asian', stay_length_col) },
      asian_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'asian', stay_length_col) },
      black_af_american: ->(race_data, stay_length_col) { single_race(race_data, 'black_af_american', stay_length_col) },
      black_af_american_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'black_af_american', stay_length_col) },
      mid_east_n_african: ->(race_data, stay_length_col) { single_race(race_data, 'mid_east_n_african', stay_length_col) },
      mid_east_n_african_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'mid_east_n_african', stay_length_col) },
      native_hi_pacific: ->(race_data, stay_length_col) { single_race(race_data, 'native_hi_pacific', stay_length_col) },
      native_hi_pacific_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'native_hi_pacific', stay_length_col) },
      white: ->(race_data, stay_length_col) { single_race(race_data, 'white', stay_length_col) },
      white_hispanic_latinaeo: ->(race_data, stay_length_col) { single_race_latinaeo(race_data, 'white', stay_length_col) },

      # For interdependent race information, counting is u sed to determinethe number of true values
      # recorded in a client's race hash.
      # The hash is keyed using Arel here because the stay_length_col is in a joined table
      hispanic_latinaeo: ->(race_data, stay_length_col) do
        race_data.select { |client_race_hash| client_race_hash[sp_c_t['hispanic_latinaeo']] }.
          select { |client_race_hash| client_race_hash.except(sp_c_t['id'], stay_length_col).values.count(true) == 1 }.
          map { |client_race_hash| client_race_hash[stay_length_col] }
      end,

      multi_racial: ->(race_data, stay_length_col) do
        race_data.reject { |client_race_hash| client_race_hash[sp_c_t['hispanic_latinaeo']] }.
          select { |client_race_hash| client_race_hash.except(sp_c_t['id'], sp_c_t['hispanic_latinaeo'], stay_length_col).values.count(true) > 1 }.
          map { |client_race_hash| client_race_hash[stay_length_col] }
      end,

      multi_racial_hispanic_latinaeo: ->(race_data, stay_length_col) do
        race_data.select { |client_race_hash| client_race_hash[sp_c_t['hispanic_latinaeo']] }.
          select { |client_race_hash| client_race_hash.except(sp_c_t['id'], sp_c_t['hispanic_latinaeo'], stay_length_col).values.count(true) > 1 }.
          map { |client_race_hash| client_race_hash[stay_length_col] }
      end,

      race_none: ->(race_data, stay_length_col) do
        race_data.select { |client_race_hash| client_race_hash.except(sp_c_t['id'], sp_c_t['hispanic_latinaeo'], stay_length_col).values.all?(false) }.
          map { |client_race_hash| client_race_hash[stay_length_col] }
      end,
    }.freeze
  end

  private def race_and_ethnicity_data
    @race_and_ethnicity_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = race_and_ethnicity_counts[:project_type_counts]
      ph_counts = race_and_ethnicity_counts[:ph_counts]
      return_counts = race_and_ethnicity_counts[:return_counts]

      race_ethnicity_combinations.each_value.with_index do |race_and_ethnicity, i|
        row = [race_and_ethnicity]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][race_and_ethnicity]

          color = config.color_for('ethnicity', i)
          bg_color = color.background_color
          data['colors'][race_and_ethnicity] = bg_color
          data['labels']['colors'][race_and_ethnicity] = color.calculated_foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][race_and_ethnicity]
          color = config.color_for('ethnicity', i)
          bg_color = color.background_color
          data['colors'][race_and_ethnicity] = bg_color
          data['labels']['colors'][race_and_ethnicity] = color.calculated_foreground_color(bg_color)
          row << count
        end
        count = return_counts[race_and_ethnicity]
        color = config.color_for('ethnicity', i)
        bg_color = color.background_color
        data['colors'][race_and_ethnicity] = bg_color
        data['labels']['colors'][race_and_ethnicity] = color.calculated_foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
