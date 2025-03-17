# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StartDateDq::Report, type: :model do
  # Shared context for StartDateDq testing
  shared_context 'start date dq test setup' do
    let(:user) { create(:acl_user) }

    let(:role) do
      create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true)
    end
    before do
      setup_access_control(user, role, Collection.system_collection(:data_sources))
    end

    let(:default_filter) do
      Filters::FilterBase.new(
        user_id: user.id,
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
      )

      if exit_date.present?
        create(
          :hud_exit,
          enrollment: enrollment,
          exit_date: exit_date,
          data_source: data_source,
          personal_id: client.personal_id,
        )
      end

      enrollment
    end

    def setup_service_history
      # Build ServiceHistoryEnrollments
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)
    end
  end

  describe 'Basic functionality' do
    include_context 'start date dq test setup'

    let(:report) { described_class.new(user.id, default_filter) }
    let(:es_project) { create_project(project_type: 1) } # ES
    let(:client) { create_client_with_warehouse_link }

    before do
      # Create enrollments with different DateToStreetESSH scenarios

      # Scenario 1: DateToStreetESSH before EntryDate (positive days between)
      create_enrollment(
        client: client,
        project: es_project,
        entry_date: '2022-11-01'.to_date,
        exit_date: '2022-12-01'.to_date,
        date_to_street_essh: '2022-10-15'.to_date,
        household_id: 'test_household_1',
      )

      # Scenario 2: DateToStreetESSH after EntryDate (negative days between)
      create_enrollment(
        client: client,
        project: es_project,
        entry_date: '2023-01-15'.to_date,
        exit_date: '2023-03-15'.to_date,
        date_to_street_essh: '2023-01-20'.to_date,
        household_id: 'test_household_2',
      )

      # Scenario 3: DateToStreetESSH same as EntryDate (0 days between)
      create_enrollment(
        client: client,
        project: es_project,
        entry_date: '2023-05-01'.to_date,
        exit_date: nil, # Still active
        date_to_street_essh: '2023-05-01'.to_date,
        household_id: 'test_household_3',
      )

      # Build service history
      setup_service_history
    end

    it 'can be instantiated with default filter' do
      default_report = described_class.new(user.id)
      expect(default_report).to be_a(described_class)
      expect(default_report.title).to eq('Date Homelessness Started')
    end

    it 'can be instantiated with custom filter' do
      expect(report).to be_a(described_class)
      expect(report.filter).to eq(default_filter)
    end

    it 'returns expected column names' do
      expected_columns = [
        'Days Between Date Homelessness Started and Entry Date',
        'Date Homelessness Started (Self-Reported)',
        'Entry Date',
        'Exit Date',
        'Days between Entry Date and Exit Date (or report end)',
        'Personal ID',
        'Project',
        'Project Type',
      ]
      expect(report.column_names).to eq(expected_columns)
    end

    context 'when filtering data' do
      let(:date_to_street_filter) do
        filter = default_filter.dup
        filter.update(dates_to_compare: :date_to_street_to_entry)
        filter
      end

      let(:length_of_time_filter) do
        filter = default_filter.dup
        filter.update(
          dates_to_compare: :date_to_street_to_entry,
          length_of_times: ['<0 days', '0-30 days'],
        )
        filter
      end

      let(:date_to_street_report) { described_class.new(user.id, date_to_street_filter) }
      let(:length_of_time_report) { described_class.new(user.id, length_of_time_filter) }

      it 'returns data when using date_to_street_to_entry comparison' do
        data = date_to_street_report.data
        expect(data).not_to be_empty

        # Basic structural checks
        expect(data.first).to respond_to(:client)
        expect(data.first).to respond_to(:enrollment)
      end

      it 'returns data when filtering by length of time' do
        data = length_of_time_report.data
        expect(data).not_to be_empty

        # All results should be either negative days or 0-30 days between
        data.each do |row|
          days_between = (row.enrollment.EntryDate - row.enrollment.DateToStreetESSH).to_i
          expect(days_between < 0 || (days_between >= 0 && days_between <= 30)).to be true
        end
      end
    end

    it 'calculates column values correctly' do
      data = report.data

      # For the first enrollment (DateToStreetESSH before EntryDate)
      first_row = data.find { |r| r.enrollment.EntryDate == '2022-11-01'.to_date }
      expect(first_row).not_to be_nil

      values = report.column_values(first_row, user)
      expect(values[:days_between]).to eq(17) # 2022-11-01 - 2022-10-15 = 17 days
      expect(values[:date_to_street]).to eq('2022-10-15'.to_date)
      expect(values[:entry_date]).to eq('2022-11-01'.to_date)
      expect(values[:exit_date]).to eq('2022-12-01'.to_date)
      expect(values[:days_between_start_and_exit]).to eq(30) # 2022-12-01 - 2022-11-01 = 30 days
    end
  end
end
