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

  describe 'member actions for a secondary reviewer' do
    include_context 'report visibility users'

    let(:report_attributes) { { start_date: 1.year.ago.to_date, end_date: Date.current, status: 'ready' } }
    let!(:reviewer_report) { report_class.create!(user_id: all_reports_user.id, secondary_reviewer_id: own_reports_user.id, **report_attributes) }

    before { sign_in(own_reports_user) }

    it 'saves a change on a scorecard the user reviews but did not create' do
      patch boston_project_scorecard_warehouse_reports_scorecard_path(reviewer_report), params: { boston_project_scorecard_report: { initial_goals_notes: 'Reviewer note' } }

      expect(reviewer_report.reload.initial_goals_notes).to eq('Reviewer note')
    end

    it 'returns not found and leaves the scorecard unchanged when updating one the user cannot see' do
      patch boston_project_scorecard_warehouse_reports_scorecard_path(others_report), params: { boston_project_scorecard_report: { initial_goals_notes: 'Reviewer note' } }

      expect(response).to have_http_status(:not_found)
      expect(others_report.reload.initial_goals_notes).to be_nil
    end
  end
end
