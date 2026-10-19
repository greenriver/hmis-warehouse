###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsProjectGroupController', type: :request do
  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_assigned_reports: true, can_view_clients: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }
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
  let!(:other_project) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID) }
  let!(:project_group) { create(:project_group, projects: [project]) }
  let!(:other_project_group) { create(:project_group, projects: [other_project]) }
  let!(:report) { create(:data_quality_report_version_five, project: nil, project_group: project_group, requestor_id: user.id) }
  let!(:other_report) { create(:data_quality_report_version_five, project: nil, project_group: other_project_group) }
  let(:support_data) do
    {
      headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'],
      counts: [[1, 'Casey', 'Example', '1980-01-01', '123456789']],
      title: 'Clients',
    }
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], project_groups: [project_group.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive).to receive(:support_for).and_return(support_data)
    sign_in(user)
  end

  def sign_in_group_contact(entity)
    contact_user = create(:acl_user)
    contact_collection = create(:collection)
    contact_collection.set_viewables({ reports: [report_definition.id] })
    setup_access_control(contact_user, create(:role, can_view_assigned_reports: true), contact_collection)
    create(:grda_warehouse_contact_project, entity: entity, user: contact_user)
    sign_out(user)
    sign_in(contact_user)
    contact_user
  end

  it 'renders support rows for a report on a group in the user collections' do
    get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED)
    expect(response.body).not_to include('Casey')
    expect(response.body).to include(destination_source_client_path(id: 1))
  end

  context 'when the user cannot view clients' do
    let!(:role) { create(:role, can_view_assigned_reports: true, can_view_projects: true) }

    it 'redirects support without rendering rows' do
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

      expect(response).to redirect_to(user.my_root_path)
      expect(response.body).not_to include('Casey')
    end

    it 'renders show for the report without support links' do
      report.update!(completed_at: Time.current)

      get project_group_data_quality_report_path(project_group, report)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("data_quality_reports/#{report.id}/support")
    end
  end

  context 'when the group has a second project the user cannot view clients for' do
    before { project_group.update!(projects: [project, other_project]) }

    it 'redirects support in HTML and xlsx' do
      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')
      expect(response).to redirect_to(user.my_root_path)

      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test', format: :xlsx)
      expect(response).to redirect_to(user.my_root_path)
    end

    it 'renders support rows once the user can view clients on both projects' do
      collection.set_viewables({ reports: [report_definition.id], project_groups: [project_group.id], projects: [project.id, other_project.id] })
      user.clear_memery_cache!

      get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(destination_source_client_path(id: 1))
    end
  end

  it 'links to support on the group report page when the user can view clients' do
    report.update!(completed_at: Time.current)

    get project_group_data_quality_report_path(project_group, report)

    expect(response.body).to include("data_quality_reports/#{report.id}/support")
  end

  it 'renders show for a contact on a project in the group without access to the group' do
    sign_in_group_contact(project)

    get project_group_data_quality_report_path(project_group, report)

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("data_quality_reports/#{report.id}/support")
  end

  it 'redirects show for a contact on a project outside the group' do
    contact_user = sign_in_group_contact(other_project)

    get project_group_data_quality_report_path(project_group, report)

    expect(response).to redirect_to(contact_user.my_root_path)
  end

  it 'redirects support for a report on a group outside the user collections without rendering rows' do
    get support_project_group_data_quality_report_path(other_project_group, other_report, individual: true, method: 'test')

    expect(response).to redirect_to(user.my_root_path)
    expect(flash[:alert]).to be_present
    expect(response.body).not_to include('Casey')
  end

  it 'returns not found when the report id belongs to a different group' do
    get support_project_group_data_quality_report_path(project_group, other_report, individual: true, method: 'test')

    expect(response).to have_http_status(:not_found)
  end

  it 'allows index for a group in the user collections' do
    get project_group_data_quality_reports_path(project_group)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include(project_group.name)
  end

  describe 'index listing' do
    let!(:colleague_report) { create(:data_quality_report_version_five, project: nil, project_group: project_group, requestor_id: create(:user).id) }

    def listed_report_ids
      Nokogiri::HTML(response.body).css('tbody a').map { |a| a['href'][/\/data_quality_reports\/(\d+)/, 1].to_i }
    end

    it 'lists only the requestor own report on the group for a user without can_view_all_reports' do
      get project_group_data_quality_reports_path(project_group)

      expect(listed_report_ids).to contain_exactly(report.id)
    end

    it 'lists every report on the group for a contact on a project in the group without access to the group' do
      sign_in_group_contact(project)

      get project_group_data_quality_reports_path(project_group)

      expect(listed_report_ids).to contain_exactly(report.id, colleague_report.id)
    end
  end

  it 'redirects index when the user lacks the report definition' do
    collection.set_viewables({ reports: [], project_groups: [project_group.id], projects: [project.id] })
    user.clear_memery_cache!

    get project_group_data_quality_reports_path(project_group)

    expect(response).to redirect_to(user.my_root_path)
  end

  it 'redirects index for a group outside the user collections' do
    get project_group_data_quality_reports_path(other_project_group)

    expect(response).to redirect_to(user.my_root_path)
  end

  describe 'project names on the report page for a group with confidential projects' do
    let!(:alpha) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Alpha Shelter', confidential: true) }
    let!(:beta) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Beta Shelter', confidential: true) }
    let(:names_role) { create(:role, can_view_confidential_project_names: true) }

    before do
      project.update!(ProjectName: 'Open Door Shelter')
      project_group.update!(projects: [project, alpha, beta])
      collection.set_viewables({ reports: [report_definition.id], project_groups: [project_group.id], projects: [project.id, alpha.id, beta.id] })
      report.update!(completed_at: Time.current)
      [project, alpha, beta].each do |p|
        Reporting::DataQualityReports::Project.create!(
          report_id: report.id,
          project_id: p.id,
          project_name: p.ProjectName,
          project_type: 1,
          bed_inventory: 10,
          unit_inventory: 10,
          average_bed_utilization: 0,
          average_unit_utilization: 0,
          nightly_client_census: {},
          nightly_household_census: {},
          calculated_at: Time.current,
        )
        Reporting::DataQualityReports::Enrollment.create!(report_id: report.id, project_id: p.id, client_id: p.id, enrolled: true, active: false, calculated_at: Time.current)
      end
      Reporting::DataQualityReports::ProjectGroup.create!(report_id: report.id, nightly_client_census: {}, nightly_household_census: {}, calculated_at: Time.current)
    end

    def list_text_under(heading)
      Nokogiri::HTML(response.body).xpath("//h4[normalize-space()='#{heading}']/following-sibling::ul[1]").text
    end

    context 'when the confidential-name permission covers only an unrelated project' do
      before do
        names_collection = create(:collection)
        names_collection.set_viewables({ projects: [other_project.id] })
        setup_access_control(user, names_role, names_collection)
      end

      it 'shows the placeholder and the public name, never the confidential names' do
        get project_group_data_quality_report_path(project_group, report)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('Hidden Alpha Shelter')
        expect(response.body).not_to include('Hidden Beta Shelter')
        expect(response.body).to include('Open Door Shelter')
        expect(response.body).to include("#{GrdaWarehouse::Hud::Project.confidential_project_name} (2)")
      end
    end

    context 'when the confidential-name permission covers the group projects' do
      before do
        names_collection = create(:collection)
        names_collection.set_viewables({ projects: [alpha.id, beta.id] })
        setup_access_control(user, names_role, names_collection)
      end

      it 'shows both confidential names in the summary and utilization lists' do
        get project_group_data_quality_report_path(project_group, report)

        expect(response).to have_http_status(:ok)
        ['Percent of Enrolled Clients Active', 'Bed Utilization', 'Unit Utilization'].each do |heading|
          expect(list_text_under(heading)).to include('Hidden Alpha Shelter', 'Hidden Beta Shelter', 'Open Door Shelter')
        end
        expect(response.body).not_to include(GrdaWarehouse::Hud::Project.confidential_project_name)
      end
    end
  end

  describe 'support rows for a group with a confidential project' do
    let!(:alpha) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Hidden Alpha Shelter', confidential: true) }
    let(:placeholder) { GrdaWarehouse::Hud::Project.confidential_project_name }
    let(:headers) { ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN', 'Project ID', 'Project'] }
    let(:support_data) do
      {
        headers: headers,
        counts: [
          [101, 'Casey', 'Example', '1980-01-01', '111223333', project.id, 'Open Door Shelter'],
          [102, 'Dana', 'Hidden', '1975-02-02', '444556666', alpha.id, 'Hidden Alpha Shelter'],
        ],
        title: 'Clients',
      }
    end

    def grant(permissions, projects)
      grant_collection = create(:collection)
      grant_collection.set_viewables({ projects: projects.map(&:id) })
      setup_access_control(user, create(:role, **permissions), grant_collection)
      user.clear_memery_cache!
    end

    def table_cells
      Nokogiri::HTML(response.body).css('table.table-hover tbody td').map { |td| td.text.strip }
    end

    def xlsx_rows
      file = Tempfile.new(['dq_group_support', '.xlsx'])
      file.binmode
      file.write(response.body)
      file.close
      sheet = Roo::Excelx.new(file.path).sheet(0)
      (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
    ensure
      file&.unlink
    end

    before do
      project.update!(ProjectName: 'Open Door Shelter')
      project_group.update!(projects: [project, alpha])
      collection.set_viewables({ reports: [report_definition.id], project_groups: [project_group.id], projects: [project.id, alpha.id] })
      user.clear_memery_cache!
    end

    after { GrdaWarehouse::Config.invalidate_cache }

    context 'when the confidential-name permission covers only the public project' do
      before { grant({ can_view_confidential_project_names: true }, [project]) }

      it 'masks the confidential project name and keeps the public one in HTML' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

        expect(response).to have_http_status(:ok)
        expect(table_cells).to include('Open Door Shelter', placeholder)
        expect(response.body).not_to include('Hidden Alpha Shelter')
      end

      it 'masks the confidential project name in xlsx' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test', format: :xlsx)

        expect(xlsx_rows.map { |r| r[6] }).to eq(['Open Door Shelter', placeholder])
      end
    end

    context 'when the confidential-name permission covers the confidential project' do
      before { grant({ can_view_confidential_project_names: true }, [alpha]) }

      it 'shows the confidential project name' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

        expect(table_cells).to include('Open Door Shelter', 'Hidden Alpha Shelter')
        expect(response.body).not_to include(placeholder)
      end
    end

    context 'when a row has no project id' do
      let(:support_data) do
        {
          headers: headers,
          counts: [[101, 'Casey', 'Example', '1980-01-01', '111223333', nil, 'Unknown']],
          title: 'Clients',
        }
      end

      before { grant({ can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true }, [project, alpha]) }

      it 'redacts name, DOB, and SSN in HTML' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

        cells = table_cells
        expect(cells).to include(GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED)
        expect(cells).not_to include('Casey', 'Example', '111-22-3333')
        expect(cells.join(' ')).not_to include('1980')
      end
    end

    context 'when a row names a soft-deleted confidential project' do
      let!(:gone) { create(:hud_project, data_source: data_source, OrganizationID: organization.OrganizationID, ProjectName: 'Deleted Secret Shelter', confidential: true) }
      let(:support_data) do
        {
          headers: headers,
          counts: [[102, 'Dana', 'Hidden', '1975-02-02', '444556666', gone.id, 'Deleted Secret Shelter']],
          title: 'Clients',
        }
      end

      before do
        grant({ can_view_client_name: true }, [project, alpha])
        gone.destroy
      end

      it 'shows the placeholder instead of the project name' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

        expect(response).to have_http_status(:ok)
        expect(table_cells).to include(placeholder)
        expect(response.body).not_to include('Deleted Secret Shelter')
      end
    end

    context 'when name, DOB, and SSN permissions cover only the public project' do
      before { grant({ can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true }, [project]) }

      it 'redacts PII on the confidential project row only in HTML' do
        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test')

        cells = table_cells
        expect(cells).to include('Casey', 'Example', '111-22-3333')
        expect(cells.join(' ')).to include('1980')
        expect(cells).not_to include('Dana', 'Hidden', '444-55-6666')
        expect(cells.join(' ')).not_to include('1975')
        expect(cells.count(GrdaWarehouse::PiiProvider::NAME_REDACTED)).to eq(2)
      end

      it 'redacts PII on the confidential project row only in xlsx' do
        GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: true)
        GrdaWarehouse::Config.invalidate_cache

        get support_project_group_data_quality_report_path(project_group, report, individual: true, method: 'test', format: :xlsx)

        public_row, confidential_row = xlsx_rows
        expect(public_row[1..2]).to eq(['Casey', 'Example'])
        expect(public_row[4].to_s).to eq('111-22-3333')
        expect(confidential_row[1..2]).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED] * 2)
        expect(confidential_row[4].to_s).not_to eq('444-55-6666')
      end
    end
  end

  it 'renders show for a report on a group in the user collections' do
    get project_group_data_quality_report_path(project_group, report)

    expect(response).to have_http_status(:ok)
  end

  it 'returns the report answers for a group in the user collections' do
    report.update!(report: { 'total_clients' => 'Viewable group answer' })

    get answers_project_group_data_quality_report_path(project_group, report)

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq('total_clients' => 'Viewable group answer')
  end

  it 'redirects answers for a report on a group outside the user collections without returning the report' do
    other_report.update!(report: { 'total_clients' => 'Hidden group answer' })

    get answers_project_group_data_quality_report_path(other_project_group, other_report)

    expect(response).to redirect_to(user.my_root_path)
    expect(response.body).not_to include('Hidden group answer')
  end

  it 'redirects show when the user lacks the report definition' do
    collection.set_viewables({ reports: [], project_groups: [project_group.id], projects: [project.id] })
    user.clear_memery_cache!

    get project_group_data_quality_report_path(project_group, report)

    expect(response).to redirect_to(user.my_root_path)
  end

  it 'redirects a logged-out request for show to sign in', :devise_only do
    sign_out(user)

    get project_group_data_quality_report_path(project_group, report)

    expect(response).to redirect_to(new_user_session_path)
  end

  it 'refuses a logged-out request for show', :jwt_only do
    sign_out(user)

    expect { get project_group_data_quality_report_path(project_group, report) }.to raise_error(Idp::UnauthenticatedRequestError)
  end

  it 'does not route the former notification path' do
    get "/notifications/abc/project_groups/#{project_group.id}/data_quality_reports/#{report.id}"

    expect(response).to have_http_status(:not_found)
  end
end
