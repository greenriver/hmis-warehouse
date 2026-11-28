###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'LSA v2 access', type: :request do
  let(:lsa_generator) { HudLsa::Generators::Fy2027::Lsa }
  # The controller seeds its filter from the user's latest run and reads that run's CoC options.
  # Each it_behaves_like block redefines run_options, which replaces the shared example's default.
  options_with_coc = { 'start' => '2025-10-01', 'end' => '2026-09-30', 'project_ids' => [], 'coc_code' => 'XX-500', 'coc_codes' => ['XX-500'] }

  describe 'LSA pages' do
    it_behaves_like 'HUD report access' do
      let(:definition_url) { 'hud_reports/lsas' }
      let(:run_options) { options_with_coc }
      let(:report_name) { lsa_generator.title }
      let(:run_attributes) { { type: lsa_generator.name } }
      let(:index_path) { hud_reports_lsas_path }
      let(:new_path) { new_hud_reports_lsa_path }
      let(:history_path) { history_hud_reports_lsas_path }
      let(:report_path_for) { ->(run) { hud_reports_lsa_path(run) } }

      it "opens a retired-year run for its owner and 404s another user's" do
        retired = HudLsa::Generators::Fy2024::Lsa
        mine = create(:hud_reports_report_instance, type: retired.name, user: user, report_name: retired.title, options: run_options)
        theirs = create(:hud_reports_report_instance, type: retired.name, user: other_user, report_name: retired.title, options: run_options)
        granted

        get hud_reports_lsa_path(mine)
        expect(response).to have_http_status(:ok)
        get hud_reports_lsa_path(theirs)
        expect(response).to have_http_status(:not_found)
      end

      it 'opens data_missing when the definition is granted' do
        granted
        get data_missing_hud_reports_lsas_path
        expect(response).to have_http_status(:ok)
      end

      it 'redirects data_missing when the definition is not granted' do
        not_granted
        get data_missing_hud_reports_lsas_path
        expect(response).to redirect_to(warehouse_reports_path)
        expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
      end
    end
  end

  describe 'LSA HIC pages' do
    it_behaves_like 'HUD report access' do
      let(:definition_url) { 'hud_reports/lsas' }
      let(:run_options) { options_with_coc }
      let(:report_name) { lsa_generator.title }
      let(:run_attributes) do
        {
          type: lsa_generator.name,
          options: run_options.merge('lsa_scope' => HudLsa::Fy2026::Report.available_lsa_scopes['HIC']),
        }
      end
      let(:index_path) { hud_reports_lsa_hics_path }
      let(:new_path) { new_hud_reports_lsa_hic_path }
      let(:history_path) { history_hud_reports_lsa_hics_path }
      let(:report_path_for) { ->(run) { hud_reports_lsa_hic_path(run) } }
    end
  end
end
