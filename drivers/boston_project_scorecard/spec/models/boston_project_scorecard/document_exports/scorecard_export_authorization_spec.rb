###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BostonProjectScorecard::DocumentExports::ScorecardExport, type: :model do
  let(:report_class) { BostonProjectScorecard::Report }
  let(:report_definition_url) { 'boston_project_scorecard/warehouse_reports/scorecards' }

  it_behaves_like 'a document export limited to visible reports' do
    let(:query_key) { 'report_id' }
    let(:report_attributes) { { start_date: 1.year.ago.to_date, end_date: Date.current } }

    it 'authorizes a scorecard the user is the secondary reviewer on' do
      report = report_class.create!(user_id: all_reports_user.id, secondary_reviewer_id: own_reports_user.id, **report_attributes)

      expect(export_for(own_reports_user, report.id).authorized?).to be(true)
    end
  end
end
