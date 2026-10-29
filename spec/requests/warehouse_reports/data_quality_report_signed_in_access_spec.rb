###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Data quality report access without a token', type: :request do
  let!(:collection) { create(:collection) }
  let!(:assigned_role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:all_reports_role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }
  let!(:other_user) { create(:acl_user) }

  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end

  let!(:data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: data_source) }
  let!(:project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { create(:dq_project_group) }

  let!(:own_project_report) { create(:data_quality_report_version_five, project: project, requestor_id: user.id, report: { 'source' => 'own project report' }) }
  let!(:others_project_report) { create(:data_quality_report_version_five, project: project, requestor_id: other_user.id, report: { 'source' => 'others project report' }) }
  let!(:own_group_report) { create(:data_quality_report_version_five, project_group: project_group, requestor_id: user.id, report: { 'source' => 'own group report' }) }
  let!(:others_group_report) { create(:data_quality_report_version_five, project_group: project_group, requestor_id: other_user.id, report: { 'source' => 'others group report' }) }

  def project_url(action, report)
    helper = {
      show: :project_data_quality_report_path,
      answers: :answers_project_data_quality_report_path,
      support: :support_project_data_quality_report_path,
    }.fetch(action)
    public_send(helper, project.id, report.id)
  end

  def group_url(action, report)
    helper = {
      show: :project_group_data_quality_report_path,
      answers: :answers_project_group_data_quality_report_path,
      support: :support_project_group_data_quality_report_path,
    }.fetch(action)
    public_send(helper, project_group.id, report.id)
  end

  def grant(role, reports: [report_definition.id])
    Collection.maintain_system_groups
    collection.set_viewables({ reports: reports, projects: [project.id], project_groups: [project_group.id] })
    setup_access_control(user, role, collection)
    sign_in(user)
  end

  context 'with access to the report and its project, without can_view_all_reports' do
    before { grant(assigned_role) }

    it 'shows a project report the user requested' do
      get project_url(:show, own_project_report)
      expect(response).to have_http_status(:ok)
    end

    it 'shows a project group report the user requested' do
      get group_url(:show, own_group_report)
      expect(response).to have_http_status(:ok)
    end

    it 'returns answers for a project report the user requested' do
      get project_url(:answers, own_project_report)
      expect(response.parsed_body).to eq('source' => 'own project report')
    end

    it 'returns answers for a project group report the user requested' do
      get group_url(:answers, own_group_report)
      expect(response.parsed_body).to eq('source' => 'own group report')
    end

    [:show, :answers, :support].each do |action|
      it "denies #{action} of a project report another user requested" do
        get project_url(action, others_project_report)
        expect(response).to redirect_to(user.my_root_path)
      end

      it "denies #{action} of a project group report another user requested" do
        get group_url(action, others_group_report)
        expect(response).to redirect_to(user.my_root_path)
      end
    end

    it 'denies a project report with no requestor' do
      own_project_report.update_columns(requestor_id: nil)

      get project_url(:answers, own_project_report)
      expect(response).to redirect_to(user.my_root_path)
    end
  end

  context 'with can_view_all_reports' do
    before { grant(all_reports_role) }

    it 'returns answers for a project report another user requested' do
      get project_url(:answers, others_project_report)
      expect(response.parsed_body).to eq('source' => 'others project report')
    end

    it 'returns answers for a project group report another user requested' do
      get group_url(:answers, others_group_report)
      expect(response.parsed_body).to eq('source' => 'others group report')
    end
  end

  context 'as the requestor without access to the report definition' do
    before { grant(all_reports_role, reports: []) }

    it 'denies a project report the user requested' do
      get project_url(:answers, own_project_report)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'denies a project group report the user requested' do
      get group_url(:answers, own_group_report)
      expect(response).to redirect_to(user.my_root_path)
    end
  end
end
