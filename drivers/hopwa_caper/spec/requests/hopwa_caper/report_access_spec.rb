###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HOPWA CAPER run access', type: :request do
  generator = HopwaCaper::Generators::Fy2026::Generator
  let(:question) { generator.questions.keys.first }
  let!(:user) { create(:user) }
  let!(:own_run) do
    create(
      :hud_reports_report_instance,
      user: user,
      report_name: generator.title,
      build_for_questions: generator.questions.keys,
      options: {},
    )
  end
  let!(:other_run) do
    create(
      :hud_reports_report_instance,
      user: create(:user),
      report_name: generator.title,
      build_for_questions: generator.questions.keys,
      options: {},
    )
  end
  let!(:apr_run) do
    create(:hud_reports_report_instance, user: user, report_name: HudApr::Generators::Apr::Fy2026::Generator.title)
  end

  def result_page(run)
    result_hud_reports_hopwa_caper_question_path(hopwa_caper_id: run.id, id: question)
  end

  def cell_page(run)
    hud_reports_hopwa_caper_question_cell_path(hopwa_caper_id: run.id, question_id: question, id: 'B2', table: 'Q1')
  end

  shared_examples 'a HOPWA run page' do
    context 'when the user has the HOPWA grant' do
      before do
        grant_hud_report(user, 'hud_reports/hopwa_capers')
        sign_in(user)
      end

      it 'renders the user\'s own run' do
        get page_for.call(own_run)

        expect(response.status).to eq(expected_own_status)
      end

      it 'returns 404 for another user\'s run without can_view_all_hud_reports' do
        get page_for.call(other_run)

        expect(response).to have_http_status(:not_found)
      end

      it 'returns 404 for a run of a different HUD report' do
        get page_for.call(apr_run)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the user lacks the HOPWA grant' do
      before { sign_in(user) }

      it 'redirects without rendering the run' do
        get page_for.call(own_run)

        expect(response).to have_http_status(:redirect)
        expect(response.body).not_to include(generator.title)
      end
    end
  end

  describe 'question result page' do
    let(:page_for) { method(:result_page) }
    let(:expected_own_status) { 200 }

    include_examples 'a HOPWA run page'
  end

  describe 'cell page' do
    let(:page_for) { method(:cell_page) }
    let(:expected_own_status) { 302 }

    include_examples 'a HOPWA run page'
  end
end
