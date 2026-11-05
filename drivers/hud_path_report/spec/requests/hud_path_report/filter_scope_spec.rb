###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HudPathReport filter scope', type: :request, exclude_fixpoints: true do
  before(:all) { GrdaWarehouse::Utility.clear! }
  after(:all) { GrdaWarehouse::Utility.clear! }

  let!(:config) { create(:config) }
  let(:data_source) { create(:source_data_source) }
  let(:coc_code) { 'XX-500' }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:visible_project) { create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 4) }
  let!(:hidden_project) { create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 4) }
  let(:role) { create(:role, can_view_assigned_reports: true) }
  let(:filter_params) do
    {
      start: '2025-10-01',
      end: '2026-09-30',
      coc_codes: [coc_code],
      report_version: 'fy2026',
      project_ids: [visible_project.id, hidden_project.id],
    }
  end

  around do |example|
    adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    example.run
  ensure
    ActiveJob::Base.queue_adapter = adapter
  end

  before do
    [visible_project, hidden_project].each do |project|
      create(:hud_project_coc, data_source_id: data_source.id, ProjectID: project.ProjectID, CoCCode: coc_code)
    end
  end

  it 'does not route edit or update for PATH runs' do
    expect(Rails.application.routes.url_helpers).not_to respond_to(:edit_hud_reports_path_path)
    expect { Rails.application.routes.recognize_path('/hud_reports/paths/1', method: :patch) }.
      to raise_error(ActionController::RoutingError)
  end

  context 'with an ACL user' do
    let(:user) { create(:acl_user) }

    before do
      collection = create(:collection)
      collection.set_viewables(projects: [visible_project.id])
      setup_access_control(user, role, collection)
      grant_hud_report(user, 'hud_reports/paths', role: role)
      sign_in(user)
    end

    it 'stores only projects the user can report on for a full run' do
      expect { post hud_reports_paths_path, params: { filter: filter_params } }.
        to change(HudReports::ReportInstance, :count).by(1)

      report = HudReports::ReportInstance.last
      expect(report.project_ids).to contain_exactly(visible_project.id)
      expect(Array(report.options['project_ids']).map(&:to_i)).to contain_exactly(visible_project.id)
    end

    it 'stores only projects the user can report on for a single question run' do
      expect { post hud_reports_path_questions_path(path_id: 0), params: { question: 'Q8-Q16', filter: filter_params } }.
        to change(HudReports::ReportInstance, :count).by(1)

      expect(HudReports::ReportInstance.last.project_ids).to contain_exactly(visible_project.id)
    end

    it 'stores the no-project sentinel when every posted project is out of scope' do
      post hud_reports_paths_path, params: { filter: filter_params.merge(project_ids: [hidden_project.id]) }

      expect(HudReports::ReportInstance.last.project_ids).to eq([0])
    end

    it 'stores the requested question for a single question run' do
      post hud_reports_path_questions_path(path_id: 0), params: { question: 'Q17: Services Provided', filter: filter_params }

      expect(HudReports::ReportInstance.last.build_for_questions).to eq(['Q17: Services Provided'])
    end

    it 'stores the fallback question when the requested name is not a PATH question' do
      post hud_reports_path_questions_path(path_id: 0), params: { question: 'Not A Question', filter: filter_params }

      expect(HudReports::ReportInstance.last.build_for_questions).to eq(['Q8-Q16'])
    end
  end

  context 'with a legacy role-based user' do
    let(:user) { create(:user) }

    before do
      grant_hud_report(user, 'hud_reports/paths', role: role)
      user.add_viewable(visible_project)
      sign_in(user)
    end

    it 'stores only the projects granted to the user' do
      post hud_reports_paths_path, params: { filter: filter_params }

      expect(HudReports::ReportInstance.last.project_ids).to contain_exactly(visible_project.id)
    end
  end
end
