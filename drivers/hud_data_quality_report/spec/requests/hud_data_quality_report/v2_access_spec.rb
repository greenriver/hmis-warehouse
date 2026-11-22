###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Past DQ v2 access', type: :request do
  it_behaves_like 'HUD report access' do
    let(:definition_url) { 'hud_reports/dqs' }
    let(:report_name) { HudDataQualityReport::Generators::Fy2022::Generator.title }
    let(:run_attributes) { { options: run_options.merge('report_version' => 'fy2022') } }
    let(:index_path) { hud_reports_past_dqs_path }
    let(:new_path) { new_hud_reports_past_dq_path }
    let(:history_path) { history_hud_reports_past_dqs_path }
    let(:report_path_for) { ->(run) { hud_reports_past_dq_path(run) } }

    it "opens the question result page for the user's own run and 404s another user's" do
      granted
      get result_hud_reports_past_dq_question_path(past_dq_id: own_run.id, id: 'Question 1')
      expect(response).to have_http_status(:ok)
      get result_hud_reports_past_dq_question_path(past_dq_id: other_run.id, id: 'Question 1')
      expect(response).to have_http_status(:not_found)
    end
  end
end
