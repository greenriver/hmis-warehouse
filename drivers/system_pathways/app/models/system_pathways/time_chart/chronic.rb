###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::Chronic
  extend ActiveSupport::Concern

  private def chronic_at_entry_chart_data
    {
      chart: 'chronic_at_entry',
      config: {
        size: {
          height: 900,
        },
      },
      data: chronic_at_entry_data,
      table: as_table(chronic_at_entry_table_data, ['Project Type'] + chronic_at_entries.values),
      link_params: {
        columns: [[]] + chronic_at_entries.keys.map { |k| ['details[chronic_at_entries][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def chronic_at_entry_table_data
    chronic_at_entry_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = chronic_at_entry_counts[:project_type_counts].merge(chronic_at_entry_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = chronic_at_entry_counts[:return_counts]
    flat_counts
  end

  def chronic_at_entry_counts
    @chronic_at_entry_counts ||= {}.tap do |e_counts|
      e_counts[:project_type_counts] = project_type_node_names.map do |label|
        data = {}
        chronic_at_entries.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:chronic_at_entry).average(sp_e_t[:stay_length]).transform_values(&:round))

        [
          label,
          data,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_projects.map do |p_type, p_label|
        data = {}
        chronic_at_entries.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(p_type).group(:chronic_at_entry).average(sp_e_t[:days_to_move_in]).transform_values(&:round))
        [
          p_label,
          data,
        ]
      end.to_h
      data = {}
      chronic_at_entries.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(node_clients('Served by Homeless System').
        group(:chronic_at_entry).
        where(sp_c_t[:days_to_return].not_eq(nil)).
        average(sp_c_t[:days_to_return]).transform_values(&:round))

      e_counts[:return_counts] = data
    end
  end

  private def chronic_at_entry_data
    @chronic_at_entry_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = chronic_at_entry_counts[:project_type_counts]
      ph_counts = chronic_at_entry_counts[:ph_counts]
      return_counts = chronic_at_entry_counts[:return_counts]

      chronic_at_entries.each.with_index do |(k, chronic_at_entry), i|
        row = [chronic_at_entry]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][k]

          color = config.color_for('chronic', i)
          bg_color = color.background_color
          data['colors'][chronic_at_entry] = bg_color
          data['labels']['colors'][chronic_at_entry] = color.calculated_foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][k]
          color = config.color_for('chronic', i)
          bg_color = color.background_color
          data['colors'][chronic_at_entry] = bg_color
          data['labels']['colors'][chronic_at_entry] = color.calculated_foreground_color(bg_color)
          row << count
        end
        count = return_counts[k]
        color = config.color_for('chronic', i)
        bg_color = color.background_color
        data['colors'][chronic_at_entry] = bg_color
        data['labels']['colors'][chronic_at_entry] = color.calculated_foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
