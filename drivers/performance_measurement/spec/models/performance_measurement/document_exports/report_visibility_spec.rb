###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PerformanceMeasurement::DocumentExports::ReportExport, type: :model do
  let(:report_class) { PerformanceMeasurement::Report }
  let(:report_definition_url) { 'performance_measurement/warehouse_reports/reports' }

  it_behaves_like 'a document export limited to visible reports' do
    let(:report_attributes) { { goal_configuration: create(:performance_measurement_goal) } }
  end
end
