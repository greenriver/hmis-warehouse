###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'SPM v2 access', type: :request do
  it_behaves_like 'HUD report access' do
    let(:definition_url) { 'hud_reports/spms' }
    let(:report_name) { HudSpmReport::Generators::Fy2026::Generator.title }
    let(:index_path) { hud_reports_spms_path }
    let(:new_path) { new_hud_reports_spm_path }
    let(:history_path) { history_hud_reports_spms_path }
    let(:report_path_for) { ->(run) { hud_reports_spm_path(run) } }

    let(:legacy_report) { Report.create!(name: 'Legacy SPM', type: 'Reports::SystemPerformance::Fy2019::MeasureOne', enabled: true) }

    it 'opens a legacy SPM report for a user granted the SPM definition' do
      granted
      expect(HudReports::ReportInstance.where(id: legacy_report.id)).to be_empty
      get hud_reports_legacy_spm_path(legacy_report)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(legacy_report.name)
    end

    it 'redirects the legacy SPM report when the SPM definition is not granted' do
      not_granted
      expect(HudReports::ReportInstance.where(id: legacy_report.id)).to be_empty
      get hud_reports_legacy_spm_path(legacy_report)
      expect(response).to redirect_to(warehouse_reports_path)
      expect(flash[:alert]).to eq('Sorry you are not authorized to do that.')
    end
  end
end
