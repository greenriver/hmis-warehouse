###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../models/fy2026/shared_context'

RSpec.describe 'HudSpmReport CellsController Integration', type: :request do
  include_context '2026 SPM test setup'

  let(:user) { create(:user) }
  # Project columns are not client PII; the policy only gates client name/dob/ssn.
  let(:pii_policy) { GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance }

  shared_examples 'drilldown show behavior' do
    it 'renders the drilldown page with the expected client' do
      get hud_reports_spm_measure_cell_path(
        spm_id: report.id,
        measure_id: measure_id,
        id: cell_id,
        table: table,
      )

      expect(response).to be_successful
      expect(response.body).to include(expected_client.personal_id)

      # Verify that the drilldown context and clients are correctly assigned
      expect(assigns(:drilldown)).to be_present
      expect(assigns(:drilldown).measure).to eq(measure_id)
      expect(assigns(:drilldown).cell).to eq(cell_id)
      expect(assigns(:drilldown).table).to eq(table)

      # Check that the client list contains our test client and the noise client
      expect(assigns(:clients)).to be_present
      expect(assigns(:clients).size).to be >= 2

      client_ids = assigns(:clients).map(&:client_id)

      expected_warehouse_id = GrdaWarehouse::WarehouseClient.find_by(source_id: expected_client.id).destination_id
      noise_warehouse_id = GrdaWarehouse::WarehouseClient.find_by(source_id: noise_client.id).destination_id

      expect(client_ids).to include(expected_warehouse_id)
      expect(client_ids).to include(noise_warehouse_id)
      expect(assigns(:clients).first).to be_a(record_class)
    end
  end

  shared_examples 'drilldown search behavior' do
    it 'supports searching for a client within the drilldown' do
      # Search for the existing client
      search_term = expected_client.personal_id
      query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: search_term })

      get search_hud_reports_spm_measure_cell_path(
        spm_id: report.id,
        measure_id: measure_id,
        id: cell_id,
        query_id: query.id,
        table: table,
      )

      expect(response).to be_successful
      expect(response.body).to include(expected_client.personal_id)
      expect(assigns(:drilldown).search_term).to eq(search_term)

      # Verify that our specific test client is returned but NOT the noise client
      client_ids = assigns(:clients).map(&:client_id)
      expected_warehouse_id = GrdaWarehouse::WarehouseClient.find_by(source_id: expected_client.id).destination_id
      noise_warehouse_id = GrdaWarehouse::WarehouseClient.find_by(source_id: noise_client.id).destination_id

      expect(client_ids).to include(expected_warehouse_id)
      expect(client_ids).not_to include(noise_warehouse_id)
      expect(assigns(:clients).size).to eq(1)

      # Search for something that doesn't exist
      non_existent_term = "NonExistent#{measure_id}#{cell_id}".gsub(' ', '')
      query_none = create(:grda_warehouse_client_search_query, created_by: user, params: { q: non_existent_term })

      get search_hud_reports_spm_measure_cell_path(
        spm_id: report.id,
        measure_id: measure_id,
        id: cell_id,
        query_id: query_none.id,
        table: table,
      )

      expect(response).to be_successful
      expect(assigns(:clients)).to be_empty
    end
  end

  before do
    # can_view_projects is granted here, not per-example: User memoizes its effective
    # permissions on first use, setup_report triggers that via HudFilterBase, and Warden
    # hands the view this very instance. Granting later would not be seen.
    user.legacy_roles << create(:role, can_view_own_hud_reports: true, can_view_projects: true)
    sign_in(user)
  end

  describe 'GET #show for Episode based measures' do
    before do
      # Setup data using performance helpers
      @es_project = create_project(project_type: 0)
      @client = create_client_with_warehouse_link(first_name: 'Drilldown', last_name: 'TestClient')
      @noise_client = create_client_with_warehouse_link(first_name: 'Noise', last_name: 'OtherClient')

      [@client, @noise_client].each do |c|
        create_enrollment(
          client: c,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
        )
      end

      # Setup and run the report for Measure 1
      @report = setup_report([@es_project.id], ['Measure 1'])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    include_examples 'drilldown show behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 1' }
      let(:cell_id) { 'B2' }
      let(:table) { '1a' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
      let(:record_class) { HudSpmReport::Fy2026::Episode }
    end

    include_examples 'drilldown search behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 1' }
      let(:cell_id) { 'B2' }
      let(:table) { '1a' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
    end
  end

  describe 'GET #show for an Episode spanning two projects' do
    before do
      @project_a = create_project(project_type: 0)
      @project_b = create_project(project_type: 0)
      @client = create_client_with_warehouse_link(first_name: 'MultiProject', last_name: 'TestClient')

      create_enrollment(
        client: @client,
        project: @project_a,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-12-15'.to_date,
      )
      create_enrollment(
        client: @client,
        project: @project_b,
        entry_date: '2022-12-15'.to_date,
        exit_date: '2023-01-15'.to_date,
      )

      @report = setup_report([@project_a.id, @project_b.id], ['Measure 1'])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'lists both HMIS ProjectIDs in one column, in entry-date order' do
      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 1',
        id: 'B2',
        table: '1a',
      )

      expect(response).to be_successful
      expect(assigns(:drilldown).headers.values).to include('Projects', 'Data Source ID')

      row = assigns(:clients).first
      expect(row.projects).to eq([@project_a, @project_b])
      expect(row.display_value('project_hmis_ids', pii_policy: pii_policy)).to eq(
        "#{@project_a.ProjectID}; #{@project_b.ProjectID}",
      )

      # Each ID links to its own project page, since an HMIS ProjectID is only unique
      # within a data source.
      expect(row.projects_by_column['project_hmis_ids']).to eq([@project_a, @project_b])
      expect(response.body).to include("#{@project_a.ProjectName} (#{@project_a.ProjectID})")
      expect(response.body).to include("#{@project_b.ProjectName} (#{@project_b.ProjectID})")
      expect(response.body).to include(project_path(id: @project_a.id))
      expect(response.body).to include(project_path(id: @project_b.id))
    end
  end

  describe 'GET #show for SpmEnrollment based measures' do
    before do
      # Setup data for Measure 4 (Income changes)
      @ph_project = create_project(project_type: 3)
      create(
        :hud_funder,
        project: @ph_project,
        data_source: @ph_project.data_source,
        Funder: HudHelper.util('2026').spm_coc_funders.first,
        StartDate: '2019-01-01'.to_date,
      )

      @client = create_client_with_warehouse_link(first_name: 'Measure4', last_name: 'TestClient')
      @noise_client = create_client_with_warehouse_link(first_name: 'Noise4', last_name: 'OtherClient')

      [@client, @noise_client].each do |c|
        enrollment = create_enrollment(
          client: c,
          project: @ph_project,
          entry_date: '2022-01-01'.to_date,
          exit_date: nil,
        )

        # Add income info for Measure 4 (Increased income)
        create(
          :hud_income_benefit,
          enrollment: enrollment,
          data_source: enrollment.data_source,
          data_collection_stage: 1,
          information_date: enrollment.entry_date,
          earned_amount: 500,
          total_monthly_income: 600,
        )
        add_income_snapshot(
          enrollment: enrollment,
          information_date: '2023-01-15'.to_date,
          data_collection_stage: 5,
          earned_amount: 700,
          other_income_amount: 200,
        )
      end

      # Run Measure 4
      @report = setup_report([@ph_project.id], ['Measure 4'])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureFour)
    end

    include_examples 'drilldown show behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 4' }
      let(:cell_id) { 'C2' }
      let(:table) { '4.1' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
      let(:record_class) { HudSpmReport::Fy2026::SpmEnrollment }
    end

    include_examples 'drilldown search behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 4' }
      let(:cell_id) { 'C2' }
      let(:table) { '4.1' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
    end

    it 'shows the HMIS ProjectID for each row' do
      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 4',
        id: 'C2',
        table: '4.1',
      )

      expect(response).to be_successful
      expect(assigns(:drilldown).headers.values).to include('Project')

      row = assigns(:clients).first
      expect(row.display_value('enrollment.project.ProjectID', pii_policy: pii_policy)).to eq(@ph_project.ProjectID)

      # The drilldown links the ID to the project page; the download keeps the plain ID.
      expect(row.projects_by_column['enrollment.project.ProjectID']).to eq([@ph_project])
      expect(response.body).to include("#{@ph_project.ProjectName} (#{@ph_project.ProjectID})")
      expect(response.body).to include(project_path(id: @ph_project.id))
    end

    it 'masks a confidential project name in the drilldown but keeps the HMIS ProjectID' do
      @ph_project.update!(confidential: true)

      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 4',
        id: 'C2',
        table: '4.1',
      )

      expect(response).to be_successful

      # This user can view projects but not confidential project names, so the name is
      # masked while the ID keeps the row identifiable.
      expect(response.body).to include(
        "#{GrdaWarehouse::Hud::Project.confidential_project_name} (#{@ph_project.ProjectID})",
      )
      expect(response.body).not_to include("#{@ph_project.ProjectName} (#{@ph_project.ProjectID})")

      # The download is unaffected: it carries the ID, never the name.
      expect(assigns(:drilldown).export_headers.keys).to include('enrollment.project.ProjectID')
    end

    it 'shows the HMIS ProjectID without a link when the user cannot view projects' do
      # The controller loads current_user fresh from the database each request; it is never this
      # `user` object. Revoke it on the persisted role instead
      user.legacy_roles.each { |role| role.update!(can_view_projects: false, can_edit_projects: false) }

      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 4',
        id: 'C2',
        table: '4.1',
      )

      expect(response).to be_successful
      expect(response.body).to include(@ph_project.ProjectID)
      expect(response.body).not_to include(project_path(id: @ph_project.id))
    end

    it 'keeps the project column when PII is excluded from downloads' do
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:include_pii_in_detail_downloads).and_return(false)

      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 4',
        id: 'C2',
        table: '4.1',
      )

      expect(response).to be_successful
      export_keys = assigns(:drilldown).export_headers.keys

      expect(export_keys).to include('enrollment.project.ProjectID')
      expect(export_keys).not_to include('first_name', 'last_name')

      # Downloads swap in DenyPiiPolicy. Project attribution must survive it: stripping
      # client PII is not a reason to hide which project a row came from.
      row = assigns(:clients).first
      deny_policy = GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance
      expect(row.display_value('enrollment.project.ProjectID', pii_policy: deny_policy)).to eq(@ph_project.ProjectID)
    end
  end

  describe 'GET #show for Return based measures' do
    before do
      @es_project = create_project(project_type: 0)
      @return_project = create_project(project_type: 0)
      @client = create_client_with_warehouse_link(first_name: 'Measure2', last_name: 'TestClient')
      @noise_client = create_client_with_warehouse_link(first_name: 'Noise2', last_name: 'OtherClient')

      [@client, @noise_client].each do |c|
        # Permanent housing exit two years before the reporting period
        create_enrollment(
          client: c,
          project: @es_project,
          entry_date: '2020-12-01'.to_date,
          exit_date: '2021-05-15'.to_date,
          destination: 410,
          living_situation: 1,
        )

        # Return to homelessness within 181-365 day window, at a different project
        create_enrollment(
          client: c,
          project: @return_project,
          entry_date: '2022-01-10'.to_date,
          exit_date: '2022-02-20'.to_date,
          living_situation: 1,
        )
      end

      @report = setup_report([@es_project.id, @return_project.id], ['Measure 2'])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureTwo)
    end

    include_examples 'drilldown show behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 2' }
      let(:cell_id) { 'B3' }
      let(:table) { '2a and 2b' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
      let(:record_class) { HudSpmReport::Fy2026::Return }
    end

    include_examples 'drilldown search behavior' do
      let(:report) { @report }
      let(:measure_id) { 'Measure 2' }
      let(:cell_id) { 'B3' }
      let(:table) { '2a and 2b' }
      let(:expected_client) { @client }
      let(:noise_client) { @noise_client }
    end

    it 'shows the exit and return HMIS ProjectIDs in separate columns' do
      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 2',
        id: 'B3',
        table: '2a and 2b',
      )

      expect(response).to be_successful
      expect(assigns(:drilldown).headers.values).to include(
        'Exited Project',
        'Returned Project',
        'Data Source ID',
      )

      # The two legs are different projects, so the columns are provably independent.
      row = assigns(:clients).first
      expect(row.display_value('exit_enrollment.enrollment.project.ProjectID', pii_policy: pii_policy)).to eq(@es_project.ProjectID)
      expect(row.display_value('return_enrollment.enrollment.project.ProjectID', pii_policy: pii_policy)).to eq(@return_project.ProjectID)

      expect(response.body).to include(project_path(id: @es_project.id))
      expect(response.body).to include(project_path(id: @return_project.id))
    end
  end

  describe 'Pagination' do
    before do
      allow_any_instance_of(HudSpmReport::CellsController).to receive(:pagination_limit).and_return(5)

      @es_project = create_project(project_type: 0)
      # Create 7 clients to trigger pagination (limit is 5)
      @clients = 7.times.map do |i|
        client = create_client_with_warehouse_link(first_name: "Client#{i}", last_name: 'PaginationTest')
        create_enrollment(
          client: client,
          project: @es_project,
          entry_date: '2022-11-01'.to_date,
          exit_date: '2023-01-15'.to_date,
        )
        client
      end

      @report = setup_report([@es_project.id], ['Measure 1'])
      run_measure(@report, HudSpmReport::Generators::Fy2026::MeasureOne)
    end

    it 'paginates the client list' do
      # Get the first page
      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 1',
        id: 'B2',
        table: '1a',
      )

      expect(response).to be_successful
      expect(assigns(:clients).size).to eq(5)
      expect(assigns(:pagy).count).to eq(7)
      expect(assigns(:pagy).pages).to eq(2)

      # Get the second page
      get hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 1',
        id: 'B2',
        table: '1a',
        page: 2,
      )

      expect(response).to be_successful
      expect(assigns(:clients).size).to eq(2)
    end

    it 'paginates search results' do
      # Search for the common last name 'PaginationTest'
      search_term = 'PaginationTest'
      query = create(:grda_warehouse_client_search_query, created_by: user, params: { q: search_term })

      # Get the first page of search results
      get search_hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 1',
        id: 'B2',
        query_id: query.id,
        table: '1a',
      )

      expect(response).to be_successful
      expect(assigns(:clients).size).to eq(5)
      expect(assigns(:pagy).count).to eq(7)

      # Get the second page of search results
      get search_hud_reports_spm_measure_cell_path(
        spm_id: @report.id,
        measure_id: 'Measure 1',
        id: 'B2',
        query_id: query.id,
        table: '1a',
        page: 2,
      )

      expect(response).to be_successful
      expect(assigns(:clients).size).to eq(2)
    end
  end
end
