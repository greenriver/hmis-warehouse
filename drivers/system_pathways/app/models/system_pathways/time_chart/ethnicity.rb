###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::Ethnicity
  extend ActiveSupport::Concern

  private def ethnicity_chart_data
    {
      chart: 'ethnicity',
      config: {
        size: {
          height: 2400,
        },
      },
      data: ethnicity_data,
      table: as_table(ethnicity_table_data, ['Project Type'] + ethnicities.values),
      link_params: {
        columns: [[]] + ethnicities.keys.map { |k| ['details[ethnicities][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def ethnicity_table_data
    race_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = ethnicity_counts[:project_type_counts].merge(ethnicity_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = ethnicity_counts[:return_counts]
    flat_counts
  end

  private def ethnicity_counts # rubocop:disable Metrics/AbcSize
    hispanic_latinaeo_column = sp_c_t['hispanic_latinaeo']
    @ethnicity_counts ||= {}.tap do |e_counts|
      project_type_counts = project_type_node_names.map do |label|
        counts = {}
        ethnicities.each_key do |k|
          counts[k] ||= 0
        end
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:stay_length]
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id))
        race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Stay Length'), scope)

        data = race_data.select { |row| row[hispanic_latinaeo_column] }.map { |m| m[stay_length_col] }
        counts[:hispanic_latinaeo] = average(data.sum, data.count).round
        data = race_data.
          select { |row| row.except(stay_length_col, hispanic_latinaeo_column).values.any?(true) }.
          reject { |row| row[hispanic_latinaeo_column] }.
          map { |m| m[stay_length_col] }
        counts[:non_hispanic_latinaeo] = average(data.sum, data.count).round
        data = race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
        counts[:unknown] = average(data.sum, data.count).round
        [
          label,
          counts,
        ]
      end.to_h
      e_counts[:project_type_counts] = project_type_counts

      ph_counts = ph_projects.map do |p_type, p_label|
        counts = {}
        ethnicities.each_key do |k|
          counts[k] ||= 0
        end
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:days_to_move_in]
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(p_type).select(:id)).where(stay_length_col.not_eq(nil))
        race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Move-In'), scope)

        data = race_data.select { |row| row[hispanic_latinaeo_column] }.map { |m| m[stay_length_col] }
        counts[:hispanic_latinaeo] = average(data.sum, data.count).round
        data = race_data.
          select { |row| row.except(stay_length_col, hispanic_latinaeo_column).values.any?(true) }.
          reject { |row| row[hispanic_latinaeo_column] }.
          map { |m| m[stay_length_col] }
        counts[:non_hispanic_latinaeo] = average(data.sum, data.count).round
        data = race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
        counts[:unknown] = average(data.sum, data.count).round
        [
          p_label,
          counts,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_counts

      label = 'Served by Homeless System'
      counts = {}
      ethnicities.each_key do |k|
        counts[k] ||= 0
      end
      # Get rid of the distinct from node_clients
      stay_length_col = sp_c_t[:days_to_return]
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id)).where(stay_length_col.not_eq(nil))
      race_data = pluck_to_hash(race_columns.except('race_none', 'multi_racial').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Return'), scope)

      data = race_data.select { |row| row[hispanic_latinaeo_column] }.map { |m| m[stay_length_col] }
      counts[:hispanic_latinaeo] = average(data.sum, data.count).round
      data = race_data.
        select { |row| row.except(stay_length_col, hispanic_latinaeo_column).values.any?(true) }.
        reject { |row| row[hispanic_latinaeo_column] }.
        map { |m| m[stay_length_col] }
      counts[:non_hispanic_latinaeo] = average(data.sum, data.count).round
      data = race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
      counts[:unknown] = average(data.sum, data.count).round
      e_counts[:return_counts] = counts
    end
  end

  private def ethnicity_data
    @ethnicity_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = ethnicity_counts[:project_type_counts]
      ph_counts = ethnicity_counts[:ph_counts]
      return_counts = ethnicity_counts[:return_counts]

      ethnicities.each.with_index do |(key, ethnicity), i|
        row = [ethnicity]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][key]

          color = config.color_for('ethnicity', i)
          bg_color = color.background_color
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = color.calculated_foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][key]
          color = config.color_for('ethnicity', i)
          bg_color = color.background_color
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = color.calculated_foreground_color(bg_color)
          row << count
        end
        count = return_counts[key]
        color = config.color_for('ethnicity', i)
        bg_color = color.background_color
        data['colors'][ethnicity] = bg_color
        data['labels']['colors'][ethnicity] = color.calculated_foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
