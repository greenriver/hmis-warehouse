###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https:#//github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module SystemPathways::Equity::Veteran
  extend ActiveSupport::Concern

  private def veteran_chart_data
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
        columns: [[]] + veteran_statuses.keys.map { |k| ['details[veteran_statuses][]', k] },
        rows: [[]] + node_names.map { |k| ['node', k] },
      },
    }
  end

  def veteran_status_counts
    @veteran_status_counts ||= node_names.map do |label|
      data = {}
      veteran_statuses.each_key do |k|
        data[k] ||= 0
      end
      # NOTE: you can't just use clients as it will join enrollents and each client may have more than one
      # but you can't use node_clients because the distinct will count the distinct number of veteran statuses
      single_client_scope = clients.joins(:enrollments).merge(SystemPathways::Enrollment.where(final_enrollment: true))
      data.merge!(single_client_scope.where(client_id: node_clients(label).select(:client_id)).group(:veteran_status).count)
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

          color = config.color_for('veteran-status', i)
          bg_color = color.background_color
          data['colors'][veteran_status] = bg_color
          data['labels']['colors'][veteran_status] = color.calculated_foreground_color(bg_color)
          row << count
        end
        data['columns'] << row
      end
      data['columns'] = remove_all_zero_rows(data['columns'])
    end
  end
end
