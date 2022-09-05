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
  let!(:config_setup) do
    config = GrdaWarehouse::Config.where(id: 1).first_or_create
    config.update(currently_homeless_cohort: true, enable_system_cohorts: true)
    source_export.update(effective_export_end_date: Date.new(2021, 8, 1))
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
    GrdaWarehouse::ChEnrollment.maintain!
  end

  context 'When populating system cohorts' do
    before(:each) do
      config_setup
    end

    after(:all) do
      cleanup_test_environment
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
          travel_to Date.new(2021, 3, 30) do
            GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
          end
        end

        it 'Creates a currently homeless system cohort' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.count).to eq(1)
        end

        it 'Currently homeless system cohort contains no clients' do
          expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(0)
        end
      end
    end
    context 'on enrollment date' do
      before(:each) do
        config_setup
        travel_to Date.new(2021, 3, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 4, 1) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
      end

      it 'Creates a currently homeless system cohort' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.count).to eq(1)
      end

      it 'Currently homeless system cohort contains one client' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(1)
      end

      it 'Notes the client has been added' do
        expect(GrdaWarehouse::CohortClientChange.count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').first.cohort_client.client_id).to eq(client.id)
      end
    end
    context 'pre-PH enrollment date' do
      before(:each) do
        config_setup
        travel_to Date.new(2021, 3, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 4, 1) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        ph_source_enrollment.update(PersonalID: source_client.PersonalID)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
        travel_to Date.new(2021, 5, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
      end

      it 'Currently homeless system cohort contains one client' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(1)
      end

      it 'Notes the client has been added' do
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').first.cohort_client.client_id).to eq(client.id)
      end
    end
    context 'post-PH enrollment date' do
      before(:each) do
        config_setup
        travel_to Date.new(2021, 3, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 4, 1) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        ph_source_enrollment.update(PersonalID: source_client.PersonalID)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
        travel_to Date.new(2021, 5, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 6, 2) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
      end

      it 'Currently homeless system cohort contains one client' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(1)
      end

      it 'Notes the client has been added' do
        expect(GrdaWarehouse::CohortClientChange.count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').first.cohort_client.client_id).to eq(client.id)
      end
    end
    context 'post-PH move-in enrollment date' do
      before(:each) do
        config_setup
        travel_to Date.new(2021, 3, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 4, 1) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        ph_source_enrollment.update(PersonalID: source_client.PersonalID)
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
        travel_to Date.new(2021, 5, 30) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 6, 2) do
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
        travel_to Date.new(2021, 7, 2) do
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.update_all(processed_as: nil)
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
          GrdaWarehouse::SystemCohorts::Base.update_system_cohorts
        end
      end

      it 'Currently homeless system cohort contains no clients' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(0)
      end

      it 'Notes the client has been added' do
        expect(GrdaWarehouse::CohortClientChange.count).to eq(2)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').first.cohort_client.client_id).to eq(client.id)
      end

      it 'Notes the client has been removed' do
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'No longer meets criteria').count).to eq(1)
        cohort_client_id = GrdaWarehouse::CohortClientChange.where(reason: 'No longer meets criteria').first.cohort_client_id
        deleted_cohort_client = GrdaWarehouse::CohortClient.only_deleted.find(cohort_client_id)
        expect(deleted_cohort_client.client_id).to eq(client.id)
      end
    end
    context 'using the batch back-fill process' do
      before(:each) do
        ph_source_enrollment.update(PersonalID: source_client.PersonalID)
        config_setup
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.all.each(&:rebuild_service_history!)
        GrdaWarehouse::SystemCohorts::Base.update_system_cohort_changes(range: Date.new(2021, 3, 30)..Date.new(2021, 7, 2))
      end

      it 'Currently homeless system cohort contains no clients' do
        expect(GrdaWarehouse::SystemCohorts::CurrentlyHomeless.first.cohort_clients.count).to eq(0)
      end

      it 'Notes the client has been added' do
        expect(GrdaWarehouse::CohortClientChange.count).to eq(2)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').count).to eq(1)
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'Newly identified').first.cohort_client.client_id).to eq(client.id)
      end

      it 'Notes the client has been removed' do
        expect(GrdaWarehouse::CohortClientChange.where(reason: 'No longer meets criteria').count).to eq(1)
        cohort_client_id = GrdaWarehouse::CohortClientChange.where(reason: 'No longer meets criteria').first.cohort_client_id
        deleted_cohort_client = GrdaWarehouse::CohortClient.only_deleted.find(cohort_client_id)
        expect(deleted_cohort_client.client_id).to eq(client.id)
      end
    end
  end
end
