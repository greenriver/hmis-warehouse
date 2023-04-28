###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class TimeChart
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase

    def time_groups
      project_type_node_names + ph_projects.values + ['Time to Return']
    end

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        {
          chart: 'ethnicity',
          data: ethnicity_data,
          table: as_table(ethnicity_table_data, ['Project Type'] + ethnicities.values),
          link_params: {
            columns: [[]] + ethnicities.keys.map { |k| ['filters[ethnicities][]', k] },
            rows: [[]] + node_names.map { |k| ['node', k] },
          },
        }
      when 'race'
        {
          chart: 'race',
          data: race_data,
          table: as_table(race_table_data, ['Project Type'] + races.values),
          link_params: {
            columns: [[]] + races.keys.map { |k| ['filters[races][]', k] },
            rows: [[]] + node_names.map { |k| ['node', k] },
          },
        }
      else
        {}
      end

      data
    end

    private def ph_projects
      [
        'PH - PSH',
        'PH - PH',
        'PH - OPH',
        'PH - RRH',
      ].map { |m| [m, "#{m} Pre-Move in"] }.to_h
    end

    private def ethnicity_table_data
      ethnicity_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
      flat_counts = ethnicity_counts[:project_type_counts].merge(ethnicity_counts[:ph_counts])
      flat_counts['Returned to Homelessness'] = ethnicity_counts[:return_counts]
      flat_counts
    end

    private def race_table_data
      race_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
      flat_counts = race_counts[:project_type_counts].merge(race_counts[:ph_counts])
      flat_counts['Returned to Homelessness'] = race_counts[:return_counts]
      flat_counts
    end

    def ethnicity_counts
      @ethnicity_counts ||= {}.tap do |e_counts|
        e_counts[:project_type_counts] = project_type_node_names.map do |label|
          data = {}
          ethnicities.each_key do |k|
            data[k] ||= 0
          end
          data.merge!(node_clients(label).group(:ethnicity).average(sp_e_t[:stay_length]).transform_values(&:round))

          [
            label,
            data,
          ]
        end.to_h
        e_counts[:ph_counts] = ph_projects.keys.map do |p_type|
          data = {}
          ethnicities.each_key do |k|
            data[k] ||= 0
          end
          data.merge!(node_clients(p_type).group(:ethnicity).average(sp_e_t[:days_to_move_in]).transform_values(&:round))
          [
            p_type,
            data,
          ]
        end.to_h
        data = {}
        ethnicities.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients('Served by Homeless System').
          group(:ethnicity).
          where.not(days_to_return: nil).
          average(:days_to_return).transform_values(&:round))

        e_counts[:return_counts] = data
      end
    end

    def race_counts
      @race_counts ||= {}.tap do |r_counts|
        project_type_counts = project_type_node_names.map do |label|
          counts = race_columns.values.map { |m| [m, 0] }.to_h
          # Get rid of the distinct from node_clients
          stay_length_col = sp_e_t[:stay_length]
          scope = SystemPathways::Client.where(id: node_clients(label).select(:id)).joins(:enrollments).where(stay_length_col.not_eq(nil))
          # FIXME: This needs to calculate average days, not counts, so we need to
          # also bring back the average days, but not use it in the race calculations
          race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Stay Length'), scope)
          race_columns.each do |k, race|
            data = if k == 'race_none'
              race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
            else
              race_data.select { |r| r[k] == true }.map { |m| m[stay_length_col] }
            end
            counts[race] = average(data.sum, data.count).round
          end
          [
            label,
            counts,
          ]
        end.to_h
        r_counts[:project_type_counts] = project_type_counts

        ph_counts = ph_projects.map do |p_type|
          counts = race_columns.values.map { |m| [m, 0] }.to_h
          # Get rid of the distinct from node_clients
          stay_length_col = sp_e_t[:days_to_move_in]
          scope = SystemPathways::Client.where(id: node_clients(p_type).select(:id)).joins(:enrollments).where(stay_length_col.not_eq(nil))

          race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Days to Move-In'), scope)
          race_columns.each do |k, race|
            data = if k == 'race_none'
              race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
            else
              race_data.select { |r| r[k] == true }.map { |m| m[stay_length_col] }
            end
            counts[race] = average(data.sum, data.count).round
          end

          [
            p_type,
            counts,
          ]
        end.to_h
        r_counts[:ph_counts] = ph_counts

        label = 'Served by Homeless System'
        counts = race_columns.values.map { |m| [m, 0] }.to_h
        # Get rid of the distinct from node_clients
        stay_length_col = :days_to_return
        scope = SystemPathways::Client.where(id: node_clients(label).select(:id)).where.not(stay_length_col => nil)

        race_data = pluck_to_hash(race_columns.except('race_none').merge(stay_length_col => 'Days to Return'), scope)
        race_columns.each do |k, race|
          data = if k == 'race_none'
            race_data.select { |row| row.except(stay_length_col).values.all?(false) }.map { |m| m[stay_length_col] }
          else
            race_data.select { |r| r[k] == true }.map { |m| m[stay_length_col] }
          end
          counts[race] = average(data.sum, data.count).round
        end
        r_counts[:return_counts] = counts
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

        ethnicities.each.with_index do |(k, ethnicity), i|
          row = [ethnicity]
          # Time in project
          project_type_node_names.each do |label|
            count = project_type_counts[label][k]

            bg_color = config["breakdown_3_color_#{i}"]
            data['colors'][ethnicity] = bg_color
            data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
            row << count
            data['columns'] << row
          end
          # Time before move-in
          ph_projects.each_key do |p_type|
            count = ph_counts[p_type][k]
            bg_color = config["breakdown_3_color_#{i}"]
            data['colors'][ethnicity] = bg_color
            data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
            row << count
            data['columns'] << row
          end
          count = return_counts[k]
          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
          row << count
          data['columns'] << row

          [
            ethnicity,
            data,
          ]
        end
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
        races = HudLists.race_map
        data['x'] = 'x'
        data['type'] = 'bar'
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *project_type_node_names]]

        races.each.with_index do |(k, race), i|
          row = [race]
          project_type_node_names.each do |label|
            counts = race_columns.values.map { |m| [m, 0] }.to_h
            race_data = pluck_to_hash(race_columns.except('race_none'), node_clients(label))

            counts[race] = if k == 'RaceNone'
              race_data.map(&:values).count { |m| m.all?(false) }
            else
              race_data.select { |r| r[k.underscore] == true }.count
            end
            row << (counts[race] || 0)
          end
          bg_color = config["breakdown_1_color_#{i}"]
          data['colors'][race] = bg_color
          data['labels']['colors'][race] = config.foreground_color(bg_color)
          data['columns'] << row

          [
            race,
            data,
          ]
        end
      end
    end
  end
end
