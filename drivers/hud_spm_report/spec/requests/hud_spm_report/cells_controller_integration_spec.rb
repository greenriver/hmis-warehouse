###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../models/fy2026/shared_context'

RSpec.describe 'HudSpmReport CellsController Integration', type: :request do
  include_context '2026 SPM test setup'

  let(:user) { create(:user) }

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
    user.legacy_roles << create(:role, can_view_own_hud_reports: true)
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
  end

  describe 'GET #show for Return based measures' do
    before do
      @es_project = create_project(project_type: 0)
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

        # Return to homelessness within 181-365 day window
        create_enrollment(
          client: c,
          project: @es_project,
          entry_date: '2022-01-10'.to_date,
          exit_date: '2022-02-20'.to_date,
          living_situation: 1,
        )
      end

      @report = setup_report([@es_project.id], ['Measure 2'])
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
