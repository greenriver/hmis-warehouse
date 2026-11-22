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

  end

  describe 'past run with a populated table' do
    let(:generator) { HudHic::Generators::Hic::Fy2022::Generator }
    let(:question) { generator.questions.keys.first }
    let(:user) { create(:acl_user) }
    let(:run) { create(:hud_reports_report_instance, user: user, report_name: generator.title, options: { 'on' => '2022-01-26' }) }

    before do
      run.start(question, [question])
      run.answer(question: question).update!(
        metadata: { header_row: ['Label', 'Count'], row_labels: ['Organizations'], first_column: 'B', last_column: 'B', first_row: 2, last_row: 2 },
      )
      run.answer(question: question, cell: 'B2').update!(summary: '7341', any_members: true)
      grant_hud_report(user, 'hud_reports/hics')
      sign_in(user)
    end

    it 'shows question result counts' do
      get result_hud_reports_hic_question_path(hic_id: run.id, id: question)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('7341')
    end

    it 'downloads the run as xlsx' do
      get download_hud_reports_hic_path(run, format: :xlsx)

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
      expect(response.headers['Content-Disposition']).to include("filename=#{generator.file_prefix} - ")
    end
  end
end
