###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HOPWA CAPER v2 access', type: :request do
  generator = HopwaCaper::Generators::Fy2026::Generator

  it_behaves_like 'HUD report access' do
    let(:definition_url) { 'hud_reports/hopwa_capers' }
    let(:report_name) { generator.title }
    let(:index_path) { hud_reports_hopwa_capers_path }
    let(:new_path) { new_hud_reports_hopwa_caper_path }
    let(:history_path) { history_hud_reports_hopwa_capers_path }
    let(:report_path_for) { ->(run) { hud_reports_hopwa_caper_path(run) } }
    let(:run_attributes) { { build_for_questions: generator.questions.keys, remaining_questions: [] } }

    it "opens the question result page for the user's own run and 404s another user's" do
      granted
      question = generator.questions.keys.first
      get result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: own_run.id, id: question)
      expect(response).to have_http_status(:ok)
      get result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: other_run.id, id: question)
      expect(response).to have_http_status(:not_found)
    end
  end
end
