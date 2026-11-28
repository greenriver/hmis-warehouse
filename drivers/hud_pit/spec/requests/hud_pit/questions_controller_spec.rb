###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudPit::QuestionsController#show', type: :request do
  let!(:user) { create(:acl_user) }
  let(:question) { 'Additional Homeless Populations' }

  def create_run(fiscal_year, version)
    run = create(
      :hud_reports_report_instance,
      user: user,
      report_name: "Point in Time Count - #{fiscal_year}",
      options: { 'report_version' => version },
      build_for_questions: [question],
      remaining_questions: [],
    )
    run.report_cells.create!(question: question, universe: true)
    run
  end

  let!(:fy2025_run) { create_run('FY 2025', 'fy2025') }
  let!(:fy2024_run) { create_run('FY 2024', 'fy2024') }

  before do
    grant_hud_report(user, 'hud_reports/pits')
    sign_in user
  end

  def year_tabs
    Nokogiri::HTML(response.body).css('ul.nav-tabs li.nav-item')
  end

  def active_tab_label
    year_tabs.select { |li| li['class'].to_s.split.include?('active') }.map { |li| li.at_css('a').text.strip }
  end

  def tab_href(label)
    year_tabs.map { |li| li.at_css('a') }.find { |a| a.text.strip == label }['href']
  end

  it 'switches years from a run-linked question page' do
    get hud_reports_pit_question_path(pit_id: fy2025_run.id, id: question)
    expect(active_tab_label).to eq(['PIT FY 2025 (current)'])

    get tab_href('PIT FY 2024')

    expect(response).to have_http_status(:ok)
    expect(active_tab_label).to eq(['PIT FY 2024'])
    expect(response.body).to include(report_path_fragment(fy2024_run))
    expect(response.body).not_to include(report_path_fragment(fy2025_run))
  end

  def report_path_fragment(run)
    "/hud_reports/pits/#{run.id}/"
  end
end
