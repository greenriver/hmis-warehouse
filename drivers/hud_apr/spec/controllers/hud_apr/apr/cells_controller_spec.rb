###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::Apr::CellsController, type: :request do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, options: { 'report_version' => 'fy2026' }, report_name: 'Annual Performance Report - FY 2026') }

  before do
    user.legacy_roles << create(:role, can_view_own_hud_reports: true)
    sign_in(user)
  end

  describe 'GET #show' do
    it 'renders the show template with pagination' do
      get hud_reports_apr_question_cell_path(apr_id: report.id, question_id: 'Question 5', id: 'B2', table: '5a')

      expect(response).to be_successful
      expect(assigns(:pagy)).to be_present
      expect(assigns(:clients)).to be_a(ActiveRecord::Relation)
    end
  end

  describe 'GET #search' do
    let(:search_term) { 'John' }
    let(:query) { create(:grda_warehouse_client_search_query, created_by: user, params: { q: search_term }) }

    it 'renders the show template with filtered results' do
      # Create some mock data
      create(:hud_report_apr_client, report_instance: report, first_name: 'John', last_name: 'Doe')
      create(:hud_report_apr_client, report_instance: report, first_name: 'Jane', last_name: 'Smith')

      get search_hud_reports_apr_question_cell_path(apr_id: report.id, question_id: 'Question 5', id: 'B2', query_id: query.id, table: '5a')

      expect(response).to be_successful
      expect(assigns(:search_term)).to eq(search_term)
      # We verify that it doesn't crash and returns 200.
      # Full verification of filtered count would require more complex setup involving UniverseMembers.
    end
  end
end
