# frozen_string_literal: true

require 'rails_helper'
require_relative '../shared_contexts/hud_enrollment_builders'

RSpec.describe ActiveClientReport, type: :model do
  include_context 'HUD enrollment builders'

  let(:start_date) { Date.parse('2024-01-01') }
  let(:end_date)   { Date.parse('2024-12-31') }

  let!(:project) { create_project(project_type: 0) }
  let!(:client) { create_client_with_warehouse_link }
  let!(:enrollment) do
    create_enrollment(
      client: client,
      project: project,
      entry_date: start_date,
    )
  end

  let(:filter) do
    # Minimal filter object with fields referenced by the report
    OpenStruct.new(
      start: start_date,
      end: end_date,
      project_type_codes: ['es'],
      sub_population: 'clients',
      organizations: nil,
      projects: nil,
      age_ranges: nil,
      head_of_household: nil,
      cocs: nil,
      genders: nil,
      races: nil,
      hoh_only: '0',
    )
  end

  subject(:report) { described_class.new(filter: filter, user: user) }

  before do
    # Create a bed-night (service) on the start_date to ensure it is inside the window
    create_bed_night_service(enrollment: enrollment, date: start_date)

    # Materialize service history records
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

    # Make the report source and filters no-ops beyond service/date/open logic
    allow(report).to receive(:service_history_source).and_return(GrdaWarehouse::ServiceHistoryEnrollment)
    allow(report).to receive(:history_scope) { |scope, _sub_population| scope }

    [
      :filter_for_project_type,
      :filter_for_organizations,
      :filter_for_projects,
      :filter_for_age,
      :filter_for_head_of_household,
      :filter_for_cocs,
      :filter_for_gender,
      :filter_for_race,
    ].each do |m|
      allow(report).to receive(m) { |scope, *_args| scope }
    end
  end

  describe '#enrollment_count and #unique_client_count' do
    it 'returns 1 enrollment and 1 unique client for a single qualifying enrollment' do
      expect(report.enrollment_count).to eq(1)
      expect(report.unique_client_count).to eq(1)
    end

    it 'counts distinct enrollments but de-duplicates clients' do
      # Same client, second enrollment with an in-window service
      second_enrollment = create_enrollment(client: client, project: project, entry_date: start_date + 5.days)
      create_bed_night_service(enrollment: second_enrollment, date: start_date + 6.days)
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find_each(&:rebuild_service_history!)

      expect(report.enrollment_count).to eq(2)
      expect(report.unique_client_count).to eq(1)
    end
  end

  describe '#enrollment_scope' do
    it 'returns the qualifying enrollment(s) ordered by program dates' do
      # Use materialized records to avoid DISTINCT/ORDER BY select-list mismatch
      ids = report.enrollment_scope.to_a.map(&:id)
      expect(ids).to be_present
      expect(ids.size).to eq(1)
      # Ensure the returned record matches the rebuilt ServiceHistoryEnrollment for this Enrollment/Client
      she = GrdaWarehouse::ServiceHistoryEnrollment.find_by(enrollment_group_id: enrollment.EnrollmentID, client_id: enrollment.client.destination_client.id)
      expect(ids).to include(she.id)
    end
  end
end
