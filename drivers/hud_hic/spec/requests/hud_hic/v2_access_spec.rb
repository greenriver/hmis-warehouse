###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HIC v2 access', type: :request do
  it_behaves_like 'HUD report access', except: [:new_page] do
    let(:definition_url) { 'hud_reports/hics' }
    let(:report_name) { HudHic::Generators::Hic::Fy2022::Generator.title }
    let(:index_path) { hud_reports_hics_path }
    let(:history_path) { history_hud_reports_hics_path }
    let(:report_path_for) { ->(run) { hud_reports_hic_path(run) } }

    it 'opens a question result for the run owner' do
      granted
      question = HudHic::Generators::Hic::Fy2022::Generator.questions.keys.first

      get result_hud_reports_hic_question_path(hic_id: own_run.id, id: question)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("HIC #{question}")
    end
  end
end
