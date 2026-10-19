###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'DataQualityReportsController#support', type: :request do
  utilization_totals = { 'counts' => { 'capacity' => 1, 'average_daily' => 1, 'average_daily_percentage' => 100 } }
  timeliness = { 'data' => {} }
  percent_keys = ['name', 'ssn', 'dob', 'veteran', 'ethnicity', 'race'].flat_map { |k| ["missing_#{k}_percent", "refused_#{k}_percent"] }
  percentage_keys = ['disabling_condition', 'prior_living_situation', 'destination', 'income_at_entry', 'income_at_exit'].flat_map { |k| ["missing_#{k}_percentage", "refused_#{k}_percentage"] }
  version_three_report = {
    'total_clients' => 1,
    'total_active_clients' => 1,
    'unit_utilization_totals' => utilization_totals,
    'bed_utilization_totals' => utilization_totals,
    'households' => { 'total_active_households' => 0 },
    'average_timeliness_of_entry' => timeliness,
    'average_timeliness_of_exit' => timeliness,
    'project_missing' => {},
    'length_of_stay_totals' => { 'average' => 0, 'buckets' => {} },
    'incorrect_dob' => { 'Project' => 1 },
    'missing_nights' => {},
    'service_after_close' => {},
    'individuals_at_family_projects' => {},
    'families_at_individual_projects' => {},
    'enrollments_with_no_service' => {},
  }.merge((percent_keys + percentage_keys).index_with { 0 })
  factory_attributes = {
    data_quality_report_version_three: { report: version_three_report },
    data_quality_report_version_four: { report: {} },
  }

  let!(:collection) { create(:collection) }
  let!(:role) { create(:role, can_view_all_reports: true, can_view_assigned_reports: true, can_view_clients: true, can_view_client_name: true, can_view_full_dob: true, can_view_full_ssn: true, can_view_projects: true) }
  let!(:user) { create(:acl_user) }

  let!(:report_definition) do
    GrdaWarehouse::WarehouseReports::ReportDefinition.create!(
      url: 'warehouse_reports/project/data_quality',
      name: 'Project Data Quality',
      report_group: 'Reports',
      description: 'Project Data Quality',
    )
  end

  let!(:project_data_source) { create(:grda_warehouse_data_source) }
  let!(:organization) { create(:hud_organization, data_source: project_data_source) }
  let!(:project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }
  let!(:report) { create(:data_quality_report_version_five, project: project) }

  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source_client) { create(:hmis_hud_client, data_source: hmis_ds, first_name: 'Restricted', last_name: 'Client') }
  let!(:restricted_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Restricted', LastName: 'Client') }
  let!(:open_destination_client) { create(:grda_warehouse_hud_client, FirstName: 'Open', LastName: 'Doe') }

  let(:support_data) do
    {
      headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'],
      counts: [
        [restricted_destination_client.id, 'Restricted', 'Client', Date.new(1990, 1, 1), '123-45-6789'],
        [open_destination_client.id, 'Open', 'Doe', Date.new(1985, 6, 15), '987-65-4321'],
      ],
      title: 'Test Support',
    }
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  def configure_download_toggle(enabled)
    GrdaWarehouse::Config.first_or_create.update!(include_pii_in_detail_downloads: enabled)
    GrdaWarehouse::Config.invalidate_cache
  end

  def table_cells
    Nokogiri::HTML(response.body).css('table.table-hover tbody td').map { |td| td.text.strip }
  end

  def xlsx_rows
    excel_file = Tempfile.new(['data_quality_support', '.xlsx'])
    excel_file.binmode
    excel_file.write(response.body)
    excel_file.close
    sheet = Roo::Excelx.new(excel_file.path).sheet(0)
    (sheet.first_row + 1..sheet.last_row).map { |i| sheet.row(i) }
  ensure
    excel_file&.unlink
  end

  before do
    Collection.maintain_system_groups
    collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
    setup_access_control(user, role, collection)
    allow_any_instance_of(GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionFive).to receive(:support_for).and_return(support_data)
    GrdaWarehouse::WarehouseClient.create!(destination_id: restricted_destination_client.id, source_id: restricted_source_client.id, data_source_id: hmis_ds.id, id_in_source: restricted_source_client.id.to_s)
    restricted_source_client.mark_as_restricted!(user: hmis_user)
    sign_in(user)
  end

  it 'redacts the restricted client name, DOB, and SSN and shows the unrestricted client in the HTML view' do
    get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

    expect(response).to have_http_status(:success)
    cells = table_cells
    expect(cells).to include('Open', 'Doe', '987-65-4321')
    expect(cells.join(' ')).to include('1985')
    expect(cells).not_to include('Restricted', 'Client', '123-45-6789')
    expect(cells.join(' ')).not_to include('1990')
    expect(cells.count(GrdaWarehouse::PiiProvider::NAME_REDACTED)).to eq(2)
    expect(cells.count(GrdaWarehouse::PiiProvider::REDACTED)).to eq(2)
  end

  context 'in the Excel export' do
    it 'redacts only the restricted client when include_pii_in_detail_downloads is on' do
      configure_download_toggle(true)

      get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = xlsx_rows
      restricted_row = rows.find { |r| r[0] == restricted_destination_client.id }
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(restricted_row[1..4]).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED])
      expect(open_row[1..2]).to eq(['Open', 'Doe'])
      expect(open_row[3].to_date).to eq(Date.new(1985, 6, 15))
      expect(open_row[4]).to eq('987-65-4321')
    end

    it 'redacts every client when include_pii_in_detail_downloads is off' do
      configure_download_toggle(false)

      get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)

      expect(response).to have_http_status(:success)
      rows = xlsx_rows
      open_row = rows.find { |r| r[0] == open_destination_client.id }

      expect(open_row[0]).to eq(open_destination_client.id)
      expect(open_row[1..4]).to eq([GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::NAME_REDACTED, GrdaWarehouse::PiiProvider::REDACTED, GrdaWarehouse::PiiProvider::REDACTED])
    end
  end

  context 'with more clients than the preload miss threshold' do
    let(:extra_clients) do
      Array.new(preload_miss_client_count) { |i| create(:grda_warehouse_hud_client, FirstName: "Preload#{i}", LastName: 'Coverage') }
    end
    let(:support_data) do
      {
        headers: ['Client ID', 'First Name', 'Last Name', 'DOB', 'SSN'],
        counts: extra_clients.map { |c| [c.id, c.FirstName, c.LastName, Date.new(1990, 1, 1), '123-45-6789'] },
        title: 'Test Support',
      }
    end

    it 'lists every client in the HTML view' do
      get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

      expect(response).to have_http_status(:ok)
      extra_clients.each { |c| expect(response.body).to include(c.FirstName) }
    end
  end

  context 'authorization' do
    let!(:other_project) { create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID) }
    let!(:other_report) { create(:data_quality_report_version_five, project: other_project) }

    it 'redirects a request for a report on a project outside the user collections' do
      get support_project_data_quality_report_path(other_project, other_report, individual: true, method: 'test')

      expect(response).to redirect_to(user.my_root_path)
      expect(flash[:alert]).to be_present
      expect(response.body).not_to include('Doe')
    end

    it 'redirects show when the user lacks the report definition' do
      collection.set_viewables({ reports: [], projects: [project.id] })
      user.clear_memery_cache!

      get project_data_quality_report_path(project, report)

      expect(response).to redirect_to(user.my_root_path)
    end

    it 'renders show when the report definition and the project are in different collections' do
      collection.set_viewables({ reports: [report_definition.id] })
      project_collection = create(:collection)
      project_collection.set_viewables({ projects: [project.id] })
      setup_access_control(user, role, project_collection)
      user.clear_memery_cache!

      get project_data_quality_report_path(project, report)

      expect(response).to have_http_status(:ok)
    end

    it 'redirects show and answers for a project contact without the report definition' do
      contact_user = create(:acl_user)
      setup_access_control(contact_user, create(:role, can_view_assigned_reports: true), create(:collection))
      create(:grda_warehouse_contact_project, entity: project, user: contact_user)
      report.update!(report: { 'total_clients' => 'Contact-only answer' })
      sign_out(user)
      sign_in(contact_user)

      get project_data_quality_report_path(project, report)
      expect(response).to redirect_to(contact_user.my_root_path)

      get answers_project_data_quality_report_path(project, report)
      expect(response).to redirect_to(contact_user.my_root_path)
      expect(response.body).not_to include('Contact-only answer')
    end

    it 'redirects index when the user has the project but not the report definition' do
      collection.set_viewables({ reports: [], projects: [project.id] })
      user.clear_memery_cache!

      get project_data_quality_reports_path(project)

      expect(response).to redirect_to(user.my_root_path)
    end

    describe 'index' do
      let!(:other_user) { create(:user) }
      let!(:own_report) { create(:data_quality_report_version_five, project: project, requestor_id: user.id) }
      let!(:colleague_report) { create(:data_quality_report_version_five, project: project, requestor_id: other_user.id) }

      def listed_report_ids
        Nokogiri::HTML(response.body).css('tbody a').map { |a| a['href'][/\/data_quality_reports\/(\d+)/, 1].to_i }
      end

      it 'lists every report on the project for a user with can_view_all_reports' do
        get project_data_quality_reports_path(project)

        expect(listed_report_ids).to contain_exactly(report.id, own_report.id, colleague_report.id)
      end

      it 'lists only the requestor own report for a user without can_view_all_reports' do
        role.update!(can_view_all_reports: false)
        user.clear_memery_cache!

        get project_data_quality_reports_path(project)

        expect(listed_report_ids).to contain_exactly(own_report.id)
      end

      context 'as a project contact without access to the project' do
        let!(:contact_user) { create(:acl_user) }

        before do
          contact_collection = create(:collection)
          contact_collection.set_viewables({ reports: [report_definition.id] })
          setup_access_control(contact_user, create(:role, can_view_assigned_reports: true), contact_collection)
          sign_out(user)
          sign_in(contact_user)
        end

        it 'lists every report on the project' do
          create(:grda_warehouse_contact_project, entity: project, user: contact_user)

          get project_data_quality_reports_path(project)

          expect(listed_report_ids).to contain_exactly(report.id, own_report.id, colleague_report.id)
        end

        it 'redirects index for a project the user is not a contact on' do
          create(:grda_warehouse_contact_project, entity: other_project, user: contact_user)

          get project_data_quality_reports_path(project)

          expect(response).to redirect_to(contact_user.my_root_path)
        end
      end
    end

    it 'returns the report answers for a project in the user collections' do
      report.update!(report: { 'total_clients' => 'Viewable project answer' })

      get answers_project_data_quality_report_path(project, report)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('total_clients' => 'Viewable project answer')
    end

    it 'redirects answers for a report on a project outside the user collections without returning the report' do
      other_report.update!(report: { 'total_clients' => 'Hidden project answer' })

      get answers_project_data_quality_report_path(other_project, other_report)

      expect(response).to redirect_to(user.my_root_path)
      expect(response.body).not_to include('Hidden project answer')
    end

    it 'returns not found when the report id belongs to a different project' do
      get support_project_data_quality_report_path(project, other_report, individual: true, method: 'test')

      expect(response).to have_http_status(:not_found)
    end

    it 'redirects a logged-out request for show to sign in', :devise_only do
      sign_out(user)

      get project_data_quality_report_path(project, report)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'redirects a logged-out request for answers to sign in', :devise_only do
      sign_out(user)

      get answers_project_data_quality_report_path(project, report)

      expect(response).to redirect_to(new_user_session_path)
    end

    it 'refuses a logged-out request for show', :jwt_only do
      sign_out(user)

      expect { get project_data_quality_report_path(project, report) }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    it 'refuses a logged-out request for answers', :jwt_only do
      sign_out(user)

      expect { get answers_project_data_quality_report_path(project, report) }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    it 'does not route the former notification path' do
      get "/notifications/abc/projects/#{project.id}/data_quality_reports/#{report.id}"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'support links on the report page' do
    before { report.update!(completed_at: Time.current, requestor_id: user.id) }

    it 'links enrolled client counts to support when the user can view clients' do
      get project_data_quality_report_path(project, report)

      path = support_project_data_quality_report_path(project, report, individual: true, method: :enrolled_clients)
      expect(response.body).to include(ERB::Util.html_escape(path))
    end

    factory_attributes.each do |factory, attributes|
      it "links a #{factory} report to support" do
        older_report = create(factory, project: project, requestor_id: user.id, completed_at: Time.current, **attributes)

        get project_data_quality_report_path(project, older_report)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("data_quality_reports/#{older_report.id}/support")
      end
    end
  end

  context 'as a project contact without client access' do
    let!(:contact_user) { create(:acl_user) }

    before do
      contact_collection = create(:collection)
      contact_collection.set_viewables({ reports: [report_definition.id] })
      setup_access_control(contact_user, create(:role, can_view_assigned_reports: true), contact_collection)
      create(:grda_warehouse_contact_project, entity: project, user: contact_user)
      sign_out(user)
      sign_in(contact_user)
    end

    context 'when can_view_clients covers only a different project' do
      before do
        unrelated_project = create(:hud_project, data_source: project_data_source, OrganizationID: organization.OrganizationID)
        client_collection = create(:collection)
        client_collection.set_viewables({ projects: [unrelated_project.id] })
        setup_access_control(contact_user, create(:role, can_view_clients: true, can_view_client_name: true), client_collection)
        contact_user.clear_memery_cache!
      end

      it 'redirects support in HTML and xlsx' do
        get support_project_data_quality_report_path(project, report, individual: true, method: 'test')
        expect(response).to redirect_to(contact_user.my_root_path)

        get support_project_data_quality_report_path(project, report, individual: true, method: 'test', format: :xlsx)
        expect(response).to redirect_to(contact_user.my_root_path)
      end
    end

    context 'when can_view_clients covers the project' do
      before do
        client_collection = create(:collection)
        client_collection.set_viewables({ projects: [project.id] })
        setup_access_control(contact_user, create(:role, can_view_clients: true, can_view_client_name: true), client_collection)
        contact_user.clear_memery_cache!
      end

      it 'renders support rows' do
        get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

        expect(response).to have_http_status(:ok)
        expect(table_cells).to include('Doe')
      end
    end

    it 'redirects support and does not render rows' do
      get support_project_data_quality_report_path(project, report, individual: true, method: 'test')

      expect(response).to redirect_to(contact_user.my_root_path)
      expect(response.body).not_to include('Open')
    end

    it 'shows enrolled client counts as text without a support link' do
      report.update!(completed_at: Time.current, requestor_id: user.id)

      get project_data_quality_report_path(project, report)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(ActionController::Base.helpers.pluralize(report.enrolled_client_count, 'client'))
      expect(response.body).not_to include("data_quality_reports/#{report.id}/support")
    end

    factory_attributes.each do |factory, attributes|
      it "renders a #{factory} report without support links" do
        older_report = create(factory, project: project, requestor_id: user.id, completed_at: Time.current, **attributes)

        get project_data_quality_report_path(project, older_report)

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include("data_quality_reports/#{older_report.id}/support")
      end
    end

    it 'returns the report answers' do
      report.update!(report: { 'total_clients' => 'Contact answer' })

      get answers_project_data_quality_report_path(project, report)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('total_clients' => 'Contact answer')
    end
  end

  context 'as a project contact on a confidential project' do
    let!(:contact_user) { create(:acl_user) }
    let(:placeholder) { GrdaWarehouse::Hud::Project.confidential_project_name }

    before do
      project.update!(confidential: true, ProjectName: 'Secret Shelter')
      organization.update!(OrganizationName: 'Hidden Org Name')
      report.update!(completed_at: Time.current, requestor_id: user.id)
      contact_collection = create(:collection)
      contact_collection.set_viewables({ reports: [report_definition.id] })
      setup_access_control(contact_user, create(:role, can_view_assigned_reports: true), contact_collection)
      create(:grda_warehouse_contact_project, entity: project, user: contact_user)
      sign_out(user)
      sign_in(contact_user)
    end

    it 'hides the project name on the report page' do
      get project_data_quality_report_path(project, report)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Secret Shelter')
      expect(response.body).to include(placeholder)
    end

    it 'hides the project name on the project report list' do
      get project_data_quality_reports_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Secret Shelter')
      expect(response.body).not_to include('Hidden Org Name')
      expect(response.body).to include(placeholder)
    end
  end

  context 'on a confidential project with can_edit_projects granted only on another project' do
    let(:placeholder) { GrdaWarehouse::Hud::Project.confidential_project_name }

    before do
      project.update!(confidential: true, ProjectName: 'Secret Shelter')
      role.update!(can_report_on_confidential_projects: true)
      edit_collection = create(:collection)
      edit_collection.set_viewables({ projects: [create(:hud_project, data_source: project_data_source).id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_projects: true), edit_collection)
    end

    it 'hides the project name on the project report list' do
      get project_data_quality_reports_path(project)

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Secret Shelter')
      expect(response.body).to include(placeholder)
    end

    it 'shows the project name once can_edit_projects covers the project' do
      collection.set_viewables({ reports: [report_definition.id], projects: [project.id] })
      setup_access_control(user, create(:role, can_view_projects: true, can_edit_projects: true), collection)

      get project_data_quality_reports_path(project)

      expect(response.body).to include('Secret Shelter')
    end
  end

  describe 'legacy support on a version three report' do
    let!(:legacy_report) do
      create(
        :data_quality_report_version_three,
        project: project,
        requestor_id: user.id,
        completed_at: Time.current,
        report: {},
        support: { 'missing_dob' => { 'headers' => ['Client ID', 'First Name', 'Last Name'], 'counts' => [[open_destination_client.id, 'Open', 'Doe']] } },
      )
    end

    it 'renders the rows for a known key' do
      get support_project_data_quality_report_path(project, legacy_report, key: 'missing_dob')

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Doe')
    end

    it 'returns not found without a key instead of the raw support payload' do
      get support_project_data_quality_report_path(project, legacy_report)

      expect(response).to have_http_status(:not_found)
      expect(response.body).not_to include('Doe')
    end

    it 'returns not found for an unknown key' do
      get support_project_data_quality_report_path(project, legacy_report, key: 'unknown')

      expect(response).to have_http_status(:not_found)
    end
  end
end
