require 'rails_helper'

RSpec.describe GrdaWarehouse::SystemCohorts::CurrentlyHomeless, type: :model do
  # need destination and source client, source enrollment and source disability
  let!(:client) { create :grda_warehouse_hud_client }

  let!(:ds) { create :data_source_fixed_id }
  let!(:source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source: ds,
      PersonalID: client.PersonalID,
    )
  end
  let!(:warehouse_client) do
    create(
      :warehouse_client,
      destination: client,
      source: source_client,
      data_source_id: source_client.data_source_id,
    )
  end
  # enough to get the enrollment processed
  let!(:unused_client) { create :grda_warehouse_hud_client }
  let!(:unused_source_client) do
    create(
      :grda_warehouse_hud_client,
      data_source: ds,
      PersonalID: unused_client.PersonalID,
    )
  end
  let!(:unused_warehouse_client) do
    create(
      :warehouse_client,
      destination: unused_client,
      source: unused_source_client,
      data_source_id: unused_source_client.data_source_id,
    )
  end
  let!(:source_export) do
    create(
      :hud_export,
      data_source_id: source_client.data_source_id,
    )
  end
  let!(:es_source_project) do
    create(
      :hud_project,
      ProjectType: 1,
      TrackingMethod: 1,
      ExportID: source_export.ExportID,
      data_source_id: source_client.data_source_id,
      computed_project_type: 1,
    )
  end
  let!(:ph_source_project) do
    create(
      :hud_project,
      ProjectType: 9,
      ExportID: source_export.ExportID,
      data_source_id: source_client.data_source_id,
      computed_project_type: 9,
    )
  end
  let!(:ch_source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'es',
      ProjectID: es_source_project.ProjectID,
      EntryDate: Date.new(2021, 4, 1),
      DisablingCondition: 1,
      data_source_id: source_client.data_source_id,
      PersonalID: source_client.PersonalID,
      DateToStreetESSH: Date.new(2020, 1, 1),
      LivingSituation: 16,
      LOSUnderThreshold: 1,
      ExportID: source_export.ExportID,
      TimesHomelessPastThreeYears: 4,
      MonthsHomelessPastThreeYears: 113,
    )
  end

  let!(:ph_source_enrollment) do
    create(
      :hud_enrollment,
      EnrollmentID: 'ph',
      ProjectID: ph_source_project.ProjectID,
      EntryDate: Date.new(2021, 6, 1),
      MoveInDate: Date.new(2021, 7, 1),
      DisablingCondition: 1,
      data_source_id: source_client.data_source_id,
      PersonalID: unused_source_client.PersonalID,
      DateToStreetESSH: nil,
      ExportID: source_export.ExportID,
    )
  end

  context 'When enrollment is chronically homeless' do
    before(:each) do
      config = GrdaWarehouse::Config.where(id: 1).first_or_create
      config.update(currently_homeless_cohort: true, enable_system_cohorts: true)
      # system_cohort = GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first_or_create! do |cohort|
      #   cohort.name = cohort.cohort_name
      #   cohort.system_cohort = true
      #   cohort.days_of_inactivity = 90
      # end
      # system_cohort.update(name: system_cohort.cohort_name)
      source_export.update(effective_export_end_date: Date.new(2021, 8, 1))
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
      GrdaWarehouse::ChEnrollment.maintain!
      # GrdaWarehouse::SystemCohorts::Base.update_system_cohort_changes(range: Date.new(2021, 3, 25)..Date.new(2021, 3, 1))
    end

    it 'Enrollments have processed_as' do
      expect(ch_source_enrollment.reload.processed_as).not_to be_nil
      expect(ph_source_enrollment.reload.processed_as).not_to be_nil
    end

    it 'ChEnrollment to exist and be chronically homeless' do
      expect(ch_source_enrollment.ch_enrollment).to_not be_blank
      expect(ch_source_enrollment.ch_enrollment.chronically_homeless_at_entry).to eq(true)
    end

    it 'PH Enrollment to not be chronically homeless' do
      expect(ph_source_enrollment.ch_enrollment).to_not be_blank
      expect(ph_source_enrollment.ch_enrollment&.chronically_homeless_at_entry).to eq(false)
    end

    context 'Using daily processing' do
      context 'prior to enrollment date' do
        before(:each) do
          travel_to Date.new(2021, 3, 30)
          SystemCohortsJob.set(priority: 10).perform_now
        end

        after(:each) do
          travel_back
        end

        it 'Creates a currently homeless system cohort' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.count).to eq(1)
        end

        it 'Currently homeless system cohort contains no clients' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(0)
        end
      end
      context 'on enrollment date' do
        before(:each) do
          travel_to Date.new(2021, 4, 1)
          SystemCohortsJob.set(priority: 10).perform_now
        end

        after(:each) do
          travel_back
        end

        it 'Creates a currently homeless system cohort' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.count).to eq(1)
        end

        it 'Currently homeless system cohort contains one client' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(1)
        end

        it 'Notes the client has been added' do
          expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
          expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').client_id).to eq(client.id)
        end
      end
    end
    # TODO
    # Add the second enrollment
    # Move forward to the day before the enrollment
    # re-run the adder, confirm no change
    # move forward to the day before move-in, confirm no change
    # move forward to the day after move-in, confirm removal

    # repeat same range with the batch adder, confirm "Newly Identified" on entry date
    # confirm 'No longer meets criteria' on day after move-in
    # confirm two total changes
  end
end
