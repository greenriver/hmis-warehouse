###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Report filters drop submitted projects the user can't report on, so the
# shared report project picker (filters/filter_controls/projects/_input.haml)
# must not offer projects the user can only view.
RSpec.describe 'Shared report project picker', type: :request do
  include HudReportAccess

  let!(:config) { create(:config) }
  let!(:data_source) { create(:source_data_source) }
  let!(:organization) { create(:hud_organization, data_source_id: data_source.id) }
  let!(:reportable_project) do
    create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1)
  end
  let!(:view_only_project) do
    create(:hud_project, data_source_id: data_source.id, OrganizationID: organization.OrganizationID, ProjectType: 1)
  end

  let(:user) { create(:acl_user) }
  let(:report_role) { create(:role, can_view_assigned_reports: true, can_view_project_related_filters: true) }
  let(:view_role) { create(:role, can_view_projects: true) }

  before do
    grant_project_access(user, report_role, [reportable_project], mode: :acl)
    grant_project_access(user, view_role, [view_only_project], mode: :acl)
    grant_hud_report(user, 'core_demographics_report/warehouse_reports/core', role: report_role)
    sign_in(user)
  end

  def picker_query
    get core_demographics_report_warehouse_reports_core_index_path
    expect(response).to have_http_status(:ok)
    # The sidebar links to the filter modal that renders the picker
    projects_link = Nokogiri::HTML(response.body).css('a.sb-link-prs1').find { |link| link.text == 'Projects' }
    expect(projects_link).to be_present

    get projects_link['href']
    expect(response).to have_http_status(:ok)
    select = Nokogiri::HTML(response.body).at_css('select[name="filters[project_ids][]"]')
    expect(select).to be_present
    Rack::Utils.parse_nested_query(select['data-collection-path'].split('?', 2).last)
  end

  it 'scopes the picker to the permission report filters use' do
    expect(picker_query['permission']).to eq('can_view_assigned_reports')
  end

  it 'does not offer a project the user can view but not report on' do
    # Reproduces what stimulus_select_controller.js does with data-collection-path.
    post api_projects_path(format: :json), params: picker_query
    ids = JSON.parse(response.body)['results'].flat_map { |group| group['children'] }.map { |child| child['id'] }
    expect(ids).to contain_exactly(reportable_project.id)
  end
end

# Report forms with their own project picker, whose reports drop projects the
# user can't report on
RSpec.describe 'Report form project pickers', type: :request do
  include HudReportAccess

  let!(:config) { create(:config) }
  let(:user) { create(:acl_user) }
  let(:report_role) { create(:role, can_view_assigned_reports: true) }

  before do
    sign_in(user)
  end

  def picker_query(report_url, report_path, select_name, data_attribute: 'data-collection-path')
    grant_hud_report(user, report_url, role: report_role)

    get report_path
    expect(response).to have_http_status(:ok)
    select = Nokogiri::HTML(response.body).at_css("select[name=\"#{select_name}\"]")
    expect(select).to be_present
    Rack::Utils.parse_nested_query(select[data_attribute].split('?', 2).last)
  end

  def self.picker_examples(forms)
    forms.each do |report_name, (report_url, report_path, select_name)|
      it "scopes the #{report_name} picker to projects the user can report on" do
        query = picker_query(report_url, instance_exec(&report_path), select_name)
        expect(query['permission']).to eq('can_view_assigned_reports')
      end
    end
  end

  picker_examples(
    {
      'HMIS Cross Walk' => ['warehouse_reports/hmis_cross_walks', -> { warehouse_reports_hmis_cross_walks_path }, 'filters[project_ids][]'],
      'Ad-Hoc Analysis' => ['warehouse_reports/ad_hoc_analysis', -> { warehouse_reports_ad_hoc_analysis_index_path }, 'filter[project_ids][]'],
      'Youth Export' => ['warehouse_reports/youth_export', -> { warehouse_reports_youth_export_index_path }, 'filter[project_ids][]'],
      'RRH Outcomes' => ['warehouse_reports/rrh', -> { warehouse_reports_rrh_index_path }, 'filter[project_ids][]'],
      'All Neighbors diversion projects' => [
        'all_neighbors_system_dashboard/warehouse_reports/reports',
        -> { all_neighbors_system_dashboard_warehouse_reports_reports_path },
        'filters[secondary_project_ids][]',
      ],
      'Bed Utilization' => ['warehouse_reports/bed_utilization', -> { warehouse_reports_bed_utilization_index_path }, 'filters[project_ids][]'],
      'Time Homeless for Exits' => ['warehouse_reports/time_homeless_for_exits', -> { warehouse_reports_time_homeless_for_exits_path }, 'filters[project_ids][]'],
      'Project Pass/Fail' => [
        'project_pass_fail/warehouse_reports/project_pass_fail',
        -> { project_pass_fail_warehouse_reports_project_pass_fail_index_path },
        'filters[project_ids][]',
      ],
    },
  )

  context 'with health emergency enabled' do
    let(:report_role) do
      create(:role, can_view_assigned_reports: true, can_see_health_emergency: true, can_see_health_emergency_clinical: true)
    end

    before do
      config.update!(health_emergency: 'boston_covid_19')
      GrdaWarehouse::Config.invalidate_cache
    end

    # Config.get caches the settings row outside the example's transaction
    after { GrdaWarehouse::Config.invalidate_cache }

    picker_examples(
      {
        'Health Emergency Medical Restrictions' => [
          'warehouse_reports/health_emergency/medical_restrictions',
          -> { warehouse_reports_health_emergency_medical_restrictions_path },
          'filter[project_ids][]',
        ],
      },
    )
  end

  # The dashboards picker reloads its projects from data-project-url when the
  # organization or project type changes, rather than from data-collection-path
  it 'scopes the Client Dashboard picker to projects the user can report on' do
    query = picker_query('dashboards/clients', dashboards_clients_path, 'filters[project_ids][]', data_attribute: 'data-project-url')
    expect(query['permission']).to eq('can_view_assigned_reports')
  end
end
