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

    def known_categories
      [
        ['Ethnicity', 'ethnicity'],
        ['Race', 'race'],
        ['Veteran Status', 'veteran_status'],
        ['Household Chronic at Entry', 'chronic_at_entry'],
      ]
    end

    def chart_data(chart)
      data = case chart.to_s
      when 'ethnicity'
        {
          chart: 'ethnicity',
          config: {
            size: {
              height: 800,
            },
          },
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
          config: {
            size: {
              height: 800,
            },
          },
          data: race_data,
          table: as_table(race_counts, ['Project Type'] + races.values),
          link_params: {
            columns: [[]] + races.keys.map { |k| ['filters[races][]', k] },
            rows: [[]] + node_names.map { |k| ['node', k] },
          },
        }
      when 'veteran_status'
        {
          chart: 'veteran_status',
          config: {
            size: {
              height: 800,
            },
          },
          data: veteran_status_data,
          table: as_table(veteran_status_counts, ['Project Type'] + veteran_statuses.values),
          # array for rows and array for columns to indicate which link params
          # should be attached for each
          link_params: {
            columns: [[]] + veteran_statuses.keys.map { |k| ['filters[veteran_statuses][]', k] },
            rows: [[]] + node_names.map { |k| ['node', k] },
          },
        }
      when 'chronic_at_entry'
        {
          chart: 'chronic_at_entry',
          config: {
            size: {
              height: 800,
            },
          },
          data: chronic_at_entry_data,
          table: as_table(chronic_at_entry_counts, ['Project Type'] + chronic_at_entries.values),
          # array for rows and array for columns to indicate which link params
          # should be attached for each
          link_params: {
            columns: [[]] + chronic_at_entries.keys.map { |k| ['filters[chronic_at_entries][]', k] },
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

    def veteran_status_counts
      @veteran_status_counts ||= node_names.map do |label|
        data = {}
        veteran_statuses.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:veteran_status).count)
        [
          label,
          data,
        ]
      end.to_h
    end

    private def veteran_status_data
      @veteran_status_data ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [veteran_statuses.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *node_names]]

        veteran_statuses.each.with_index do |(k, veteran_status), i|
          row = [veteran_status]
          node_names.each do |label|
            count = veteran_status_counts[label][k] || 0

            bg_color = config["breakdown_4_color_#{i}"]
            data['colors'][veteran_status] = bg_color
            data['labels']['colors'][veteran_status] = config.foreground_color(bg_color)
            row << count
            data['columns'] << row
          end
          [
            veteran_status,
            data,
          ]
        end
      end
    end

    def chronic_at_entry_counts
      @chronic_at_entry_counts ||= node_names.map do |label|
        data = {}
        chronic_at_entries.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:chronic_at_entry).count)
        [
          label,
          data,
        ]
      end.to_h
    end

    private def chronic_at_entry_data
      @chronic_at_entry_data ||= {}.tap do |data|
        data['x'] = 'x'
        data['type'] = 'bar'
        data['groups'] = [chronic_at_entries.values]
        data['colors'] = {}
        data['labels'] = { 'colors' => {}, 'centered' => true }
        data['columns'] = [['x', *node_names]]

        chronic_at_entries.each.with_index do |(k, chronic_at_entry), i|
          row = [chronic_at_entry]
          node_names.each do |label|
            count = chronic_at_entry_counts[label][k] || 0

            bg_color = config["breakdown_4_color_#{i}"]
            data['colors'][chronic_at_entry] = bg_color
            data['labels']['colors'][chronic_at_entry] = config.foreground_color(bg_color)
            row << count
            data['columns'] << row
          end
          [
            chronic_at_entry,
            data,
          ]
        end
      end
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

          [
            race,
            data,
          ]
        end
      end
    end
  end
end
