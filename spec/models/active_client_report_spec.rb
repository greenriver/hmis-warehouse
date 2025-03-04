
require 'rails_helper'

RSpec.describe ActiveClientReport, type: :model do
  let(:today) { Date.current }
  let!(:data_source) { create :grda_warehouse_data_source, authoritative: true }
  let!(:wh_data_source) { create :grda_warehouse_data_source, source_type: nil, authoritative: false }
  let!(:organization) { create :hud_organization, data_source: data_source }

  let(:role) do
    create(:role, can_view_project_related_filters: true, can_view_assigned_reports: true, can_view_projects: true)
  end

  before do
    setup_access_control(user, role, Collection.system_collection(:data_sources))
  end

  let(:user) { create :acl_user }

  let!(:project1) do
    create(
      :grda_warehouse_hud_project,
      organization: organization,
      project_type: 4,
      data_source: data_source,
    )
  end

  let!(:project2) do
    create(
      :grda_warehouse_hud_project,
      organization: organization,
      project_type: 1,
      data_source: data_source,
    )
  end

  let(:days_homeless) { 30 }

  # Base setup for clients
  let!(:source_clients) do
    2.times.map do
      source_client = create :hud_client, data_source_id: data_source.id
      client = create(:hud_client, data_source: wh_data_source)
      create :warehouse_client, source_id: source_client.id, destination_id: client.id, data_source: data_source
      source_client
    end
  end

  let(:filter) do
    params = {
      on: today,
      start: (today - 1.year),
      end: today,
      comparison_pattern: :no_comparison_period,
      household_type: :all
    }
    ::Filters::FilterBase.new(user_id: user.id).update(params)
  end

  let(:report) { described_class.new(filter: filter, user: user) }

  context 'with a single enrollment per client' do
    before do
      # Create one enrollment for each client
      source_clients.each do |source_client|
        create :hud_enrollment,
               client: source_client,
               data_source: data_source,
               project: project1,
               entry_date: today - days_homeless.days
      end

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    it 'correctly counts enrollments' do
      expect(report.enrollment_scope.size).to eq 2
    end
  end

  context 'with multiple enrollments for the same client' do
    let!(:client_with_multiple_enrollments) { source_clients.first }

    before do
      # Create one enrollment for each client in project1
      source_clients.each do |source_client|
        create :hud_enrollment,
               client: source_client,
               data_source: data_source,
               project: project1,
               entry_date: today - days_homeless.days
      end

      # Create additional enrollments for the first client
      # One more enrollment in the same project
      create :hud_enrollment,
             client: client_with_multiple_enrollments,
             data_source: data_source,
             project: project1,
             entry_date: today - (days_homeless * 2).days

      # And one enrollment in a different project
      create :hud_enrollment,
             client: client_with_multiple_enrollments,
             data_source: data_source,
             project: project2,
             entry_date: today - (days_homeless / 2).days

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    it 'correctly counts all enrollments' do
      expect(report.enrollment_scope.size).to eq 4
    end

    it 'includes all enrollments for the client with multiple enrollments' do
      client_enrollments = report.enrollment_scope.where(client_id: client_with_multiple_enrollments.destination_client.id)
      expect(client_enrollments.size).to eq 3
    end

    it 'maintains distinct enrollments' do
      # Ensure we're not duplicating enrollments
      enrollment_ids = report.enrollment_scope.map(&:id)
      expect(enrollment_ids.size).to eq enrollment_ids.uniq.size
    end

    it 'orders enrollments by first_date_in_program' do
      enrollments = report.enrollment_scope.to_a
      expect(enrollments).to eq enrollments.sort_by(&:first_date_in_program)
    end
  end

  context 'with enrollments outside the filter date range' do
    before do
      # Create enrollments within the date range
      source_clients.each do |source_client|
        create :hud_enrollment,
               client: source_client,
               data_source: data_source,
               project: project1,
               entry_date: today - days_homeless.days
      end

      # Create enrollment outside the date range
      create :hud_enrollment,
             client: source_clients.first,
             data_source: data_source,
             project: project1,
             entry_date: today - 2.years

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    it 'only includes enrollments within the filter date range' do
      expect(report.enrollment_scope.size).to eq 2
    end
  end

  context 'when filtered by project type' do
    before do
      # Create enrollments in different project types
      source_clients.each do |source_client|
        create :hud_enrollment,
               client: source_client,
               data_source: data_source,
               project: project1, # project_type: 4
               entry_date: today - days_homeless.days

        create :hud_enrollment,
               client: source_client,
               data_source: data_source,
               project: project2, # project_type: 1
               entry_date: today - days_homeless.days
      end

      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    end

    it 'filters enrollments by the specified project type' do
      # Create a filter that only includes project type 4
      filtered_params = {
        on: today,
        start: (today - 1.year),
        end: today,
        comparison_pattern: :no_comparison_period,
        household_type: :all,
        project_type_ids: [4]
      }
      filtered_filter = ::Filters::FilterBase.new(user_id: user.id).update(filtered_params)
      filtered_report = described_class.new(filter: filtered_filter, user: user)

      expect(filtered_report.enrollment_scope.size).to eq 2
      expect(filtered_report.enrollment_scope.map(&:project_type).uniq).to eq [4]
    end
  end
end
