###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::Race
  extend ActiveSupport::Concern

  private def race_chart_data
    {
      chart: 'race',
      config: {
        size: {
          height: 2400,
        },
      },
      data: race_data,
      table: as_table(race_table_data, ['Project Type'] + races.values),
      link_params: {
        columns: [[]] + races.keys.map { |k| ['details[races][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def race_table_data
    race_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = race_counts[:project_type_counts].merge(race_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = race_counts[:return_counts]
    flat_counts
  end

  def race_counts
    @race_counts ||= {}.tap do |r_counts|
      project_type_counts = project_type_node_names.map do |label|
        counts = race_columns.values.map { |m| [m, 0] }.to_h
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:stay_length]
        # scope = SystemPathways::Client.where(id: node_clients(label).select(:id)).joins(:enrollments).where(stay_length_col.not_eq(nil))
        # race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Stay Length'), scope)
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id)).where(stay_length_col.not_eq(nil))
        race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Stay Length'), scope)

        race_columns.each do |k, race|
          data = if k == 'race_none'
            race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
          else
            race_data.select { |r| r[sp_c_t[k]] == true }.map { |m| m[stay_length_col] }
          end
          counts[race] = average(data.sum, data.count).round
        end
        [
          label,
          counts,
        ]
      end.to_h
      r_counts[:project_type_counts] = project_type_counts

      ph_counts = ph_projects.map do |p_type, p_label|
        counts = race_columns.values.map { |m| [m, 0] }.to_h
        # Get rid of the distinct from node_clients
        stay_length_col = sp_e_t[:days_to_move_in]
        # scope = SystemPathways::Client.where(id: node_clients(p_type).select(:id)).joins(:enrollments).where(stay_length_col.not_eq(nil))
        # race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Days to Move-In'), scope)
        scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(p_type).select(:id)).where(stay_length_col.not_eq(nil))
        race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Move-In'), scope)
        race_columns.each do |k, race|
          data = if k == 'race_none'
            race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
          else
            race_data.select { |r| r[sp_c_t[k]] == true }.map { |m| m[stay_length_col] }
          end
          counts[race] = average(data.sum, data.count).round
        end

        [
          p_label,
          counts,
        ]
      end.to_h
      r_counts[:ph_counts] = ph_counts

      label = 'Served by Homeless System'
      counts = race_columns.values.map { |m| [m, 0] }.to_h
      # Get rid of the distinct from node_clients
      stay_length_col = sp_c_t[:days_to_return]
      # scope = SystemPathways::Client.where(id: node_clients(label).select(:id)).where(stay_length_col.not_eq(nil))
      # race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Days to Return'), scope)
      scope = SystemPathways::Enrollment.joins(:client).where(id: node_clients(label).select(:id)).where(stay_length_col.not_eq(nil))
      race_data = pluck_to_hash(race_columns.except('race_none').map { |k, v| [sp_c_t[k], v] }.to_h.merge(stay_length_col => 'Days to Return'), scope)
      race_columns.each do |k, race|
        data = if k == 'race_none'
          race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
        else
          race_data.select { |r| r[sp_c_t[k]] == true }.map { |m| m[stay_length_col] }
        end
        counts[race] = average(data.sum, data.count).round
      end
      r_counts[:return_counts] = counts
    end
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
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = race_counts[:project_type_counts]
      ph_counts = race_counts[:ph_counts]
      return_counts = race_counts[:return_counts]

      race_columns.each_value.with_index do |race, i|
        row = [race]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][race]

          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][race] = bg_color
          data['labels']['colors'][race] = config.foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][race]
          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][race] = bg_color
          data['labels']['colors'][race] = config.foreground_color(bg_color)
          row << count
        end
        count = return_counts[race]
        bg_color = config["breakdown_3_color_#{i}"]
        data['colors'][race] = bg_color
        data['labels']['colors'][race] = config.foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
