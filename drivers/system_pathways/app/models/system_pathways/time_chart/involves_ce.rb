###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::InvolvesCe
  extend ActiveSupport::Concern

  private def involves_ce_chart_data
    {
      chart: 'involves_ce',
      config: {
        size: {
          height: 900,
        },
      },
      data: involves_ce_data,
      table: as_table(involves_ce_table_data, ['Project Type'] + involves_ces.values),
      link_params: {
        columns: [[]] + involves_ces.keys.map { |k| ['details[involves_ce]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def involves_ce_table_data
    involves_ce_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = involves_ce_counts[:project_type_counts].merge(involves_ce_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = involves_ce_counts[:return_counts]
    flat_counts
  end

  def involves_ce_counts
    @involves_ce_counts ||= {}.tap do |e_counts|
      e_counts[:project_type_counts] = project_type_node_names.map do |label|
        data = {}
        involves_ces.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:involves_ce).average(sp_e_t[:stay_length]).transform_values(&:round))

        [
          label,
          data,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_projects.map do |p_type, p_label|
        data = {}
        involves_ces.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(p_type).group(:involves_ce).average(sp_e_t[:days_to_move_in]).transform_values(&:round))
        [
          p_label,
          data,
        ]
      end.to_h
      data = {}
      involves_ces.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(node_clients('Served by Homeless System').
        group(:involves_ce).
        where(sp_c_t[:days_to_return].not_eq(nil)).
        average(sp_c_t[:days_to_return]).transform_values(&:round))

      e_counts[:return_counts] = data
    end
  end

  private def involves_ce_data
    @involves_ce_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = involves_ce_counts[:project_type_counts]
      ph_counts = involves_ce_counts[:ph_counts]
      return_counts = involves_ce_counts[:return_counts]

      involves_ces.each.with_index do |(k, involves_ce), i|
        row = [involves_ce]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][k]

          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][involves_ce] = bg_color
          data['labels']['colors'][involves_ce] = config.foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][k]
          bg_color = config["breakdown_3_color_#{i}"]
          data['colors'][involves_ce] = bg_color
          data['labels']['colors'][involves_ce] = config.foreground_color(bg_color)
          row << count
        end
        count = return_counts[k]
        bg_color = config["breakdown_3_color_#{i}"]
        data['colors'][involves_ce] = bg_color
        data['labels']['colors'][involves_ce] = config.foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
