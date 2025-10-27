# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisDataQualityTool::Report, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  # Shared context for StartDateDq testing
  shared_context 'client visibility dq tool test setup' do
    let(:data_sources_collection) { Collection.system_collection(:data_sources) }

    # User 1: Can run reports AND view clients
    let(:user_with_client_access) { create(:acl_user) }
    let(:role_with_client_access) do
      create(:role,
             name: 'DQ Tool Test Role - Full Access',
             can_view_project_related_filters: true,
             can_view_assigned_reports: true,
             can_view_projects: true,
             can_view_clients: true,
             can_search_own_clients: true)
    end

    # User 2: Can run reports but NOT view clients
    let(:user_without_client_access) { create(:acl_user) }
    let(:role_without_client_access) do
      create(:role,
             name: 'DQ Tool Test Role - Report Access Only',
             can_view_project_related_filters: true,
             can_view_assigned_reports: true,
             can_view_projects: true,
             can_view_clients: false,
             can_search_own_clients: false)
    end

    # User 3: Cannot run reports nor view clients
    let(:user_no_access) { create(:acl_user) }
    let(:role_no_access) do
      create(:role,
             name: 'DQ Tool Test Role - No Access',
             can_view_project_related_filters: false,
             can_view_assigned_reports: false,
             can_view_projects: false,
             can_view_clients: false,
             can_search_own_clients: false)
    end

    before do
      setup_access_control(user_with_client_access, role_with_client_access, data_sources_collection)
      setup_access_control(user_without_client_access, role_without_client_access, data_sources_collection)
      setup_access_control(user_no_access, role_no_access, data_sources_collection)

      # Verify each user only has their assigned role
      expect(user_with_client_access.roles.reload.count).to eq(1), "user_with_client_access has #{user_with_client_access.roles.count} roles: #{user_with_client_access.roles.pluck(:name)}"
      expect(user_without_client_access.roles.reload.count).to eq(1), "user_without_client_access has #{user_without_client_access.roles.count} roles: #{user_without_client_access.roles.pluck(:name)}"
      expect(user_no_access.roles.reload.count).to eq(1), "user_no_access has #{user_no_access.roles.count} roles: #{user_no_access.roles.pluck(:name)}"
    end

    let(:client_access_filter) do
      Filters::FilterBase.new(
        user_id: user_with_client_access.id,
        start: '2022-10-01'.to_date,
        end: '2023-09-30'.to_date,
        coc_codes: ['MA-500'],
        enforce_one_year_range: false,
        dates_to_compare: :date_to_street_to_entry,
        require_service_during_range: false,
      )
    end

    let(:no_client_access_filter) do
      Filters::FilterBase.new(
        user_id: user_without_client_access.id,
        start: '2022-10-01'.to_date,
        end: '2023-09-30'.to_date,
        coc_codes: ['MA-500'],
        enforce_one_year_range: false,
        dates_to_compare: :date_to_street_to_entry,
        require_service_during_range: false,
      )
    end

    let!(:destination_data_source) { create :destination_data_source }
    let!(:data_source) { create(:source_data_source) }

    # Setup CoC organization
    let!(:organization) { create(:hud_organization, data_source: data_source) }

    def create_project(project_type:, coc_code: 'MA-500')
      project = create(
        :hud_project,
        project_type: project_type,
        organization: organization,
        data_source: data_source,
        ContinuumProject: 1,
      )

      create(
        :hud_project_coc,
        project_id: project.project_id,
        data_source: data_source,
        coc_code: coc_code,
      )

      project
    end

    def create_client_with_warehouse_link(dob: '1995-04-05'.to_date)
      client = create(:hud_client, data_source: data_source, dob: dob)
      destination_client = create(:hud_client, data_source: destination_data_source)
      create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
      client
    end

    def create_enrollment(client:, project:, entry_date:, exit_date: nil, relationship_to_ho_h: 1,
      date_to_street_essh:, household_id: Hmis::Hud::Base.generate_uuid)
      enrollment = create(
        :hud_enrollment,
        client: client,
        project: project,
        data_source: data_source,
        entry_date: entry_date,
        date_to_street_essh: date_to_street_essh,
        relationship_to_ho_h: relationship_to_ho_h,
        household_id: household_id,
        date_created: entry_date,
      )

      if exit_date.present?
        create(
          :hud_exit,
          enrollment: enrollment,
          exit_date: exit_date,
          data_source: data_source,
          personal_id: client.personal_id,
          date_created: exit_date,
        )
      end

      enrollment
    end

    def setup_service_history
      # Build ServiceHistoryEnrollments
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end
  end

  describe 'User permissions and client visibility' do
    include_context 'client visibility dq tool test setup'

    # This test suite validates:
    # 1. User permission levels (full access, report-only access, no access)
    # 2. Data quality issue detection (SSN and Name validation)
    # 3. Report generation and data aggregation

    let(:es_project) { create_project(project_type: 1) } # ES

    # Client with valid data
    let(:client_valid) do
      client = create(:hud_client,
                      data_source: data_source,
                      dob: '1990-01-01'.to_date,
                      first_name: 'Valid',
                      last_name: 'Client',
                      name_data_quality: 1,
                      ssn: '987654321',
                      ssn_data_quality: 1)
      destination_client = create(:hud_client, data_source: destination_data_source)
      create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
      client
    end

    # Client with SSN issues - blank SSN but DQ says full SSN reported
    let(:client_bad_ssn) do
      client = create(:hud_client,
                      data_source: data_source,
                      dob: '1990-01-01'.to_date,
                      first_name: 'Bad',
                      last_name: 'SSN',
                      name_data_quality: 1,
                      ssn: nil, # Blank SSN
                      ssn_data_quality: 1) # But says "Full SSN reported"
      destination_client = create(:hud_client, data_source: destination_data_source)
      create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
      client
    end

    # Client with name issues - blank first name but DQ says full name reported
    let(:client_bad_name) do
      client = create(:hud_client,
                      data_source: data_source,
                      dob: '1985-05-15'.to_date,
                      first_name: nil, # Blank first name
                      last_name: 'LastOnly',
                      name_data_quality: 1, # But says "Full name reported"
                      ssn: '987654321',
                      ssn_data_quality: 1)
      destination_client = create(:hud_client, data_source: destination_data_source)
      create(:warehouse_client, destination_id: destination_client.id, source_id: client.id)
      client
    end

    before do
      # Create enrollments for valid client
      create_enrollment(
        client: client_valid,
        project: es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-12-01'.to_date,
        date_to_street_essh: '2022-10-15'.to_date,
        household_id: 'test_household_1',
      )

      create_enrollment(
        client: client_valid,
        project: es_project,
        entry_date: '2023-01-15'.to_date,
        exit_date: '2023-03-15'.to_date,
        date_to_street_essh: '2023-01-20'.to_date,
        household_id: 'test_household_2',
      )

      create_enrollment(
        client: client_valid,
        project: es_project,
        entry_date: '2023-05-01'.to_date,
        exit_date: nil, # Still active
        date_to_street_essh: '2023-05-01'.to_date,
        household_id: 'test_household_3',
      )

      # Create enrollments for clients with data quality issues
      create_enrollment(
        client: client_bad_ssn,
        project: es_project,
        entry_date: '2023-01-01'.to_date,
        exit_date: '2023-06-01'.to_date,
        date_to_street_essh: '2023-01-01'.to_date,
        household_id: 'test_household_bad_ssn',
      )

      create_enrollment(
        client: client_bad_name,
        project: es_project,
        entry_date: '2023-02-01'.to_date,
        exit_date: '2023-07-01'.to_date,
        date_to_street_essh: '2023-02-01'.to_date,
        household_id: 'test_household_bad_name',
      )

      # Build service history
      setup_service_history
    end

    context 'with user that has full access (can run reports AND view clients)' do
      let(:report) do
        r = described_class.new(
          user_id: user_with_client_access.id,
          report_name: described_class.untranslated_title,
          manual: true,
          question_names: [],
        )
        r.filter = client_access_filter
        r.save
        r.run_and_save!
        r
      end

      it 'generates report results correctly' do
        # Verify that the report completed successfully
        expect(report.state).to eq('Completed')
        expect(report.completed_at).not_to be_nil

        # Verify that we have enrollments in the report (3 for valid client, 1 each for bad SSN and bad name)
        expect(report.enrollments.count).to eq(5)

        # Verify that we have clients in the report (1 valid, 1 with bad SSN, 1 with bad name)
        expect(report.clients.count).to eq(3)

        # Verify that results are generated
        results = report.results
        expect(results).to be_present
      end

      it 'identifies SSN data quality issues' do
        # Find the SSN issues result
        ssn_result = report.results.find { |r| r.title == 'Social Security Number' }
        expect(ssn_result).to be_present
        expect(ssn_result.invalid_count).to eq(1)

        # Get the items with SSN issues
        ssn_issues = report.items_for('Social Security Number')
        ssn_client_ids = ssn_issues.map(&:destination_client_id)
        expect(ssn_client_ids).to include(client_bad_ssn.warehouse_client_source.destination_id)
      end

      it 'identifies name data quality issues' do
        # Find the name issues result
        name_result = report.results.find { |r| r.title == 'Name' }
        expect(name_result).to be_present
        expect(name_result.invalid_count).to eq(1)

        # Get the items with name issues
        name_issues = report.items_for('Name')
        name_client_ids = name_issues.map(&:destination_client_id)
        expect(name_client_ids).to include(client_bad_name.warehouse_client_source.destination_id)
      end

      it 'allows user to see client details' do
        expect(report.can_see_client_details?(user_with_client_access)).to be true
      end
    end

    context 'with user that can run reports but cannot view clients' do
      let(:report) do
        r = described_class.new(
          user_id: user_without_client_access.id,
          report_name: described_class.untranslated_title,
          manual: true,
          question_names: [],
        )
        r.filter = no_client_access_filter
        r.save
        r.run_and_save!
        r
      end

      it 'prevents user from seeing client details' do
        expect(report.can_see_client_details?(user_without_client_access)).to be false
      end

      it 'still generates report results' do
        # Verify that the report completed successfully
        expect(report.state).to eq('Completed')
        expect(report.completed_at).not_to be_nil

        # Verify that we have enrollments in the report (same data as user with access)
        expect(report.enrollments.count).to eq(5)

        # Verify that we have clients in the report
        expect(report.clients.count).to eq(3)
      end

      it 'still identifies data quality issues even without client access' do
        # User can still see aggregate data quality results
        ssn_result = report.results.find { |r| r.title == 'Social Security Number' }
        expect(ssn_result).to be_present
        expect(ssn_result.invalid_count).to eq(1)

        name_result = report.results.find { |r| r.title == 'Name' }
        expect(name_result).to be_present
        expect(name_result.invalid_count).to eq(1)
      end
    end

    context 'with user that has no access to reports or clients' do
      let(:report) do
        # Create the report for a user with client access
        r = described_class.new(
          user_id: user_with_client_access.id,
          report_name: described_class.untranslated_title,
          manual: true,
          question_names: [],
        )
        r.filter = client_access_filter
        r.save
        r.run_and_save!
        r
      end

      it 'cannot see client details' do
        expect(report.can_see_client_details?(user_no_access)).to be false
      end
    end
  end
end
