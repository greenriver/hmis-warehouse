###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::TimeChart::Veteran
  extend ActiveSupport::Concern

  private def veteran_chart_data
    {
      chart: 'veteran_status',
      config: {
        size: {
          height: 2000,
        },
      },
      data: veteran_status_data,
      table: as_table(veteran_status_table_data, ['Project Type'] + veteran_statuses.values),
      link_params: {
        columns: [[]] + veteran_statuses.keys.map { |k| ['details[veteran_statuses][]', k] },
        rows: [[]] + detail_node_keys.map { |k| ['node', k] },
      },
    }
  end

  private def veteran_status_table_data
    veteran_status_counts[:ph_counts].transform_keys { |k| ph_projects[k] }
    flat_counts = veteran_status_counts[:project_type_counts].merge(veteran_status_counts[:ph_counts])
    flat_counts['Returned to Homelessness'] = veteran_status_counts[:return_counts]
    flat_counts
  end

  def veteran_status_counts
    @veteran_status_counts ||= {}.tap do |e_counts|
      e_counts[:project_type_counts] = project_type_node_names.map do |label|
        data = {}
        veteran_statuses.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(label).group(:veteran_status).average(sp_e_t[:stay_length]).transform_values(&:round))

        [
          label,
          data,
        ]
      end.to_h
      e_counts[:ph_counts] = ph_projects.map do |p_type, p_label|
        data = {}
        veteran_statuses.each_key do |k|
          data[k] ||= 0
        end
        data.merge!(node_clients(p_type).group(:veteran_status).average(sp_e_t[:days_to_move_in]).transform_values(&:round))
        [
          p_label,
          data,
        ]
      end.to_h
      data = {}
      veteran_statuses.each_key do |k|
        data[k] ||= 0
      end
      data.merge!(node_clients('Served by Homeless System').
        group(:veteran_status).
        where(sp_c_t[:days_to_return].not_eq(nil)).
        average(sp_c_t[:days_to_return]).transform_values(&:round))

      e_counts[:return_counts] = data
    end
  end

  private def veteran_status_data
    @veteran_status_data ||= {}.tap do |data|
      data['x'] = 'x'
      data['type'] = 'bar'
      data['colors'] = {}
      data['labels'] = { 'colors' => {}, 'centered' => true }
      data['columns'] = [['x', *time_groups]]

      project_type_counts = veteran_status_counts[:project_type_counts]
      ph_counts = veteran_status_counts[:ph_counts]
      return_counts = veteran_status_counts[:return_counts]

      ethnicities.each.with_index do |(k, veteran_status), i|
        row = [veteran_status]
        # Time in project
        project_type_node_names.each do |label|
          count = project_type_counts[label][k]

          color = config.color_for('veteran-status', i)
          bg_color = color.background_color
          data['colors'][veteran_status] = bg_color
          data['labels']['colors'][veteran_status] = color.calculated_foreground_color(bg_color)
          row << count
        end
        # Time before move-in
        ph_projects.each_value do |p_label|
          count = ph_counts[p_label][k]
          color = config.color_for('veteran-status', i)
          bg_color = color.background_color
          data['colors'][veteran_status] = bg_color
          data['labels']['colors'][veteran_status] = color.calculated_foreground_color(bg_color)
          row << count
        end
        count = return_counts[k]
        color = config.color_for('veteran-status', i)
        bg_color = color.background_color
        data['colors'][veteran_status] = bg_color
        data['labels']['colors'][veteran_status] = color.calculated_foreground_color(bg_color)
        row << count
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
