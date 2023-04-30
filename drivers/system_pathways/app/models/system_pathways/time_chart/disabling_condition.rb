###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::DisablingCondition
  extend ActiveSupport::Concern

  private def disabling_condition_chart_data
    {
      chart: 'disabling_condition',
      config: {
        size: {
          height: 2000,
        },
      },
      data: disabling_condition_data,
      table: as_table(disabling_condition_table_data, ['Project Type'] + disabling_conditions.values),
      link_params: {
        columns: [[]] + disabling_conditions.keys.map { |k| ['filters[disabling_conditions][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def disabling_condition_table_data
    disabling_condition_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = disabling_condition_counts[:project_type_counts].merge(disabling_condition_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = disabling_condition_counts[:return_counts]
    flat_counts
  end

  def disabling_condition_counts
    @disabling_condition_counts ||= {}.tap do |e_counts|
      e_counts[:project_type_counts] = project_type_node_names.map do |label|
        data = {}
        disabling_conditions.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:disabling_condition).average(sp_e_t[:stay_length]).transform_values(&:round))

        [
          label,
          data,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_projects.map do |p_type, p_label|
        data = {}
        disabling_conditions.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(p_type).group(:disabling_condition).average(sp_e_t[:days_to_move_in]).transform_values(&:round))
        [
          p_label,
          data,
        ]
      end.to_h
      data = {}
      disabling_conditions.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(node_clients('Served by Homeless System').
        group(:disabling_condition).
        where(sp_c_t[:days_to_return].not_eq(nil)).
        average(sp_c_t[:days_to_return]).transform_values(&:round))

      e_counts[:return_counts] = data
    end
  end

  private def disabling_condition_data
    @disabling_condition_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = disabling_condition_counts[:project_type_counts]
      ph_counts = disabling_condition_counts[:ph_counts]
      return_counts = disabling_condition_counts[:return_counts]

      disabling_conditions.each.with_index do |(k, disabling_condition), i|
        row = [disabling_condition]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][k]

          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][disabling_condition] = bg_color
          data['labels']['colors'][disabling_condition] = config.foreground_color(bg_color)
          row << count
          data['columns'] << row
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][k]
          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][disabling_condition] = bg_color
          data['labels']['colors'][disabling_condition] = config.foreground_color(bg_color)
          row << count
          data['columns'] << row
        end
        count = return_counts[k]
        bg_color = config["breakdown_3_color_#{i}"]
        data['colors'][disabling_condition] = bg_color
        data['labels']['colors'][disabling_condition] = config.foreground_color(bg_color)
        row << count
        data['columns'] << row

        [
          disabling_condition,
          data,
        ]
      end
    end
  end
end
