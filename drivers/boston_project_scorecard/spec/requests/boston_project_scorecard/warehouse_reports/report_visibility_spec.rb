###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'BostonProjectScorecard::WarehouseReports::ScorecardsController visibility', type: :request do
  let(:report_class) { BostonProjectScorecard::Report }
  let(:report_definition_url) { 'boston_project_scorecard/warehouse_reports/scorecards' }
  let(:report_path) { ->(report) { boston_project_scorecard_warehouse_reports_scorecard_path(report) } }

  it_behaves_like 'report member actions limited to visible reports', destroy: false do
    let(:report_attributes) { { start_date: 1.year.ago.to_date, end_date: Date.current } }
  end
end
