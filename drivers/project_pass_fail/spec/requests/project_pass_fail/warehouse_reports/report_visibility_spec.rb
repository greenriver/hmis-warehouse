###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ProjectPassFail::WarehouseReports::ProjectPassFail visibility', type: :request do
  let(:report_class) { ProjectPassFail::ProjectPassFail }
  let(:report_definition_url) { 'project_pass_fail/warehouse_reports/project_pass_fail' }
  let(:report_path) { ->(report) { project_pass_fail_warehouse_reports_project_pass_fail_path(report) } }

  it_behaves_like 'report member actions limited to visible reports' do
    let(:report_attributes) { { options: { 'filters' => {} } } }
  end
end
