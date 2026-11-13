###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.help_links << {
  controller_path: 'homeless_summary_report/warehouse_reports/reports',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/System-Performance-Measures-by-Sub-Population',
}

Rails.application.config.help_links << {
  controller_path: 'homeless_summary_report/warehouse_reports/reports',
  action_name: 'show',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/System-Performance-Measures-by-Sub-Population',
}
