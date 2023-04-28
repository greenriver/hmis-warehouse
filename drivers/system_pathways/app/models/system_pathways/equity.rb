###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
require 'memery'

module SystemPathways
  class Equity
    include ArelHelper
    include Memery
    include SystemPathways::ChartBase

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        {
          chart: 'ethnicity',
          data: ethnicity_data,
          table: as_table(ethnicity_counts, ['Project Type'] + ethnicities.values),
          # array for rows and array for columns to indicate which link params
          # should be attached for each
          link_params: {
            columns: [[]] + ethnicities.keys.map { |k| ['filters[ethnicities][]', k] },
            rows: [[]] + node_names.map { |k| ['node', k] },
          },
        }
      when 'race'
        {
          chart: 'race',
          data: race_data,
          table: as_table(race_counts, ['Project Type'] + races.values),
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

    def ethnicity_counts
      @ethnicity_counts ||= node_names.map do |label|
        data = {}
        ethnicities.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:ethnicity).count)
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

            bg_color = config["breakdown_3_color_#{i}"]
            data['colors'][ethnicity] = bg_color
            data['labels']['colors'][ethnicity] = config.foreground_color(bg_color)
            row << count
            data['columns'] << row
          end
          [
            ethnicity,
            data,
          ]
        end
      end
    end

    def race_counts
      @race_counts ||= node_names.map do |label|
        counts = race_columns.values.map { |m| [m, 0] }.to_h
        # Get rid of the distinct from node_clients
        scope = SystemPathways::Client.where(id: node_clients(label).select(:id))
        race_data = pluck_to_hash(race_columns.except('race_none'), scope)
        race_columns.each do |k, race|
          counts[race] = if k == 'race_none'
            race_data.map(&:values).count { |m| m.all?(false) }
          else
            race_data.select { |r| r[k] == true }.count
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

          [
            race,
            data,
          ]
        end
      end
    end
  end
end
