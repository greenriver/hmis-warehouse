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

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        {
          chart: 'ethnicity',
          data: ethnicity_data,
          table: ethnicity_counts,
        }
      when 'race'
        {
          chart: 'race',
          data: race_data,
          table: race_counts,
        }
      else
        {}
      end

      data
    end

    def time_groups
      project_type_node_names + ph_projects.values + ['Time to Return']
    end

    private def ph_projects
      [
        'PH - PSH',
        'PH - PH',
        'PH - OPH',
        'PH - RRH',
      ].map { |m| [m, "#{m} Pre-Move in"] }.to_h
    end

    def ethnicity_counts
      @ethnicity_counts ||= {
        project_type_counts: project_type_node_names.map do |label|
          [
            label,
            node_clients(label).group(:ethnicity).average(sp_e_t[:stay_length]),
          ]
        end.to_h,
        ph_counts: ph_projects.keys.map do |p_type|
          [
            p_type,
            node_clients(p_type).group(:ethnicity).average(sp_e_t[:days_to_move_in]),
          ]
        end.to_h,
        return_counts: node_clients('Served by Homeless System').
          group(:ethnicity).
          where.not(days_to_return: nil).
          average(:days_to_return),
      }
    end

    def race_counts
      @race_counts ||= {}.tap do |r_counts|
        project_type_counts = project_type_node_names.map do |label|
          counts = race_columns.values.map { |m| [m, 0] }.to_h
          race_data = pluck_to_hash(race_columns.except('race_none'), node_clients(label))
          races.each do |k, race|
            counts[race] = if k == 'RaceNone'
              race_data.map(&:values).count { |m| m.all?(false) }
            else
              race_data.select { |r| r[k.underscore] == true }.count
            end
          end
          [
            label,
            counts,
          ]
        end.to_h
        r_counts[:project_type_counts] = project_type_counts

        ph_counts = ph_projects.map do |p_type|
          counts = race_columns.values.map { |m| [m, 0] }.to_h
          race_data = pluck_to_hash(race_columns.except('race_none'), node_clients(p_type))
          races.each do |k, race|
            counts[race] = if k == 'RaceNone'
              race_data.map(&:values).count { |m| m.all?(false) }
            else
              race_data.select { |r| r[k.underscore] == true }.count
            end
          end
          [
            p_type,
            counts,
          ]
        end.to_h
        r_counts[:ph_counts] = ph_counts

        label = 'Served by Homeless System'
        counts = race_columns.values.map { |m| [m, 0] }.to_h
        race_data = pluck_to_hash(race_columns.except('race_none'), node_clients(label))
        races.each do |k, race|
          counts[race] = if k == 'RaceNone'
            race_data.map(&:values).count { |m| m.all?(false) }
          else
            race_data.select { |r| r[k.underscore] == true }.count
          end
        end
        r_counts[:return_counts] = counts
      end
    end

    private def ethnicity_data
      @ethnicity_data ||= {}.tap do |data|
        ethnicities = HudLists.ethnicity_map
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
            row << count.to_i
            data['columns'] << row
          end
          # Time before move-in
          ph_projects.each_key do |p_type|
            count = ph_counts[p_type][k]
            bg_color = config["breakdown_3_color_#{i}"]
            data['colors'][ethnicity] = bg_color
            data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
            row << count.to_i
            data['columns'] << row
          end
          count = return_counts[k]
          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][ethnicity] = bg_color
          data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
          row << count.to_i
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
