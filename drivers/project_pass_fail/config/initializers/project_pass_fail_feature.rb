###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

Rails.application.config.help_links << {
  controller_path: 'project_pass_fail/warehouse_reports/project_pass_fail',
  action_name: 'index',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Project-Pass-Fail',
}
Rails.application.config.help_links << {
  controller_path: 'project_pass_fail/warehouse_reports/project_pass_fail',
  action_name: 'show',
  external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Project-Pass-Fail',
}
