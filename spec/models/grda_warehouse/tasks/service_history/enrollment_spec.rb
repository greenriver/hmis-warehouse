###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::Enrollment, type: :model do
  let(:data_source) { create :source_data_source }
  let(:destination_data_source) { create :destination_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }

  def create_client_with_warehouse_link(dob:)
    source_client = create(:grda_warehouse_hud_client, data_source: data_source, DOB: dob)
    destination_client = source_client.dup
    destination_client.data_source = destination_data_source
    destination_client.save!
    create(:warehouse_client, destination_id: destination_client.id, source_id: source_client.id)
    source_client
  end

  describe '#build_for_dates' do
    context 'with entry-exit tracking project' do
      let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 0 } # ES-EE

      context 'with normal dates' do
        let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '2000-01-01' }
        let(:enrollment) do
          en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-01'
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
        end
        let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2023-01-03' }

        it 'generates dates between build_from and build_until' do
          dates = enrollment.build_for_dates

          expect(dates.keys).to contain_exactly(
            '2023-01-01'.to_date,
            '2023-01-02'.to_date,
          )
          expect(dates.values.uniq).to eq([200]) # Bed night service type
        end
      end

      context 'when EntryDate is before DOB' do
        let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '2012-01-01' }
        let(:enrollment) do
          en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '1999-12-31'
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
        end
        let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2012-01-03' }

        it 'uses DOB as build_from' do
          dates = enrollment.build_for_dates

          expect(dates.keys).to contain_exactly(
            '2012-01-01'.to_date,
            '2012-01-02'.to_date,
          )
          expect(dates.values.uniq).to eq([200]) # Bed night service type
        end
      end

      context 'when EntryDate is before 2000-01-01' do
        let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '1990-01-01' }
        let(:enrollment) do
          en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '1990-12-31'
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
        end
        let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2000-01-03' }

        it 'uses 2000-01-01 as build_from' do
          dates = enrollment.build_for_dates

          expect(dates.keys).to contain_exactly(
            '2000-01-01'.to_date,
            '2000-01-02'.to_date,
          )
          expect(dates.values.uniq).to eq([200]) # Bed night service type
        end
      end

      context 'when EntryDate is after DOB and 2000-01-01' do
        let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '2000-01-01' }
        let(:enrollment) do
          en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2015-01-01'
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
        end
        let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2015-01-03' }

        it 'uses EntryDate as build_from' do
          dates = enrollment.build_for_dates

          expect(dates.keys).to contain_exactly(
            '2015-01-01'.to_date,
            '2015-01-02'.to_date,
          )
          expect(dates.values.uniq).to eq([200]) # Bed night service type
        end
      end
    end

    context 'with night-by-night project' do
      let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 1 } # ES-NbN
      let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '2000-01-01' }
      let(:enrollment) do
        en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-01'
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
      end
      let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2023-01-03' }

      before do
        # Create some services within the date range
        create :hud_service,
               data_source_id: data_source.id,
               enrollment_id: enrollment.enrollment_id,
               personal_id: client.personal_id,
               date_provided: '2023-01-02',
               record_type: 200
        create :hud_service,
               data_source_id: data_source.id,
               enrollment_id: enrollment.enrollment_id,
               personal_id: client.personal_id,
               date_provided: '2023-01-03',
               record_type: 200
      end

      it 'only includes dates with actual services' do
        dates = enrollment.build_for_dates

        expect(dates.keys).to contain_exactly(
          '2023-01-02'.to_date,
          '2023-01-03'.to_date,
        )
        expect(dates.values.uniq).to eq([200]) # Bed night service type
      end
    end

    context 'with street outreach project' do
      let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 4 } # SO
      let(:client) { create :grda_warehouse_hud_client, data_source: data_source, DOB: '2000-01-01' }
      let(:enrollment) do
        en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-01'
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
      end
      let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2023-01-03' }

      before do
        # Create some living situations within the date range
        create :hud_current_living_situation,
               data_source_id: data_source.id,
               enrollment_id: enrollment.enrollment_id,
               personal_id: client.personal_id,
               information_date: '2023-01-02'
        create :hud_current_living_situation,
               data_source_id: data_source.id,
               enrollment_id: enrollment.enrollment_id,
               personal_id: client.personal_id,
               information_date: '2023-01-03'
      end

      it 'includes both services and living situations' do
        dates = enrollment.build_for_dates

        expect(dates.keys).to contain_exactly(
          '2023-01-02'.to_date,
          '2023-01-03'.to_date,
        )
        expect(dates.values.uniq).to eq([200]) # Bed night service type
      end
    end
  end

  describe '#rebuild_service_history!' do
    let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 0 } # ES-EE
    let!(:client) { create_client_with_warehouse_link(dob: '2000-01-01') }
    let(:enrollment) do
      en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-01'
      GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
    end

    context 'guard clauses prevent processing when' do
      it 'returns false for EntryDate before 1970-01-01' do
        enrollment.update_column(:EntryDate, '1969-12-31')
        expect(enrollment.rebuild_service_history!).to be false
      end

      it 'returns false when destination_client is missing' do
        allow(enrollment).to receive(:destination_client).and_return(nil)
        expect(enrollment.rebuild_service_history!).to be false
      end

      it 'returns false when project is missing' do
        allow(enrollment).to receive(:project).and_return(nil)
        expect(enrollment.rebuild_service_history!).to be false
      end

      it 'returns false when data_source is missing' do
        allow(enrollment).to receive(:data_source).and_return(nil)
        expect(enrollment.rebuild_service_history!).to be false
      end
    end

    context 'when enrollment needs full rebuild' do
      let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2023-01-03' }

      it 'creates service history enrollment and services' do
        result = enrollment.rebuild_service_history!

        expect(result).to eq(:update)
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: enrollment.EnrollmentID).count).to eq(2) # entry + exit
        expect(GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID },
        ).count).to eq(2) # 2 bed nights (Jan 1, Jan 2)
      end

      it 'sets processed_as hash and history_generated_on' do
        enrollment.rebuild_service_history!

        enrollment.reload
        expect(enrollment.processed_as).to be_present
        expect(enrollment.history_generated_on).to eq(Date.current)
      end
    end

    context 'when rebuilding open enrollment multiple times' do
      it 'handles subsequent rebuilds without error' do
        # First build
        first_result = enrollment.rebuild_service_history!
        expect(first_result).to eq(:update)

        enrollment.reload
        # Simulate service history being valid now
        allow(enrollment).to receive(:service_history_valid?).and_return(true)

        # Second call with valid service history - should check for patch
        # Returns false when no new dates to add (expected behavior)
        second_result = enrollment.rebuild_service_history!
        expect([false, :patch]).to include(second_result)
      end
    end

    context 'when enrollment is already processed' do
      let!(:exit) { create :hud_exit, data_source_id: data_source.id, EnrollmentID: enrollment.EnrollmentID, PersonalID: client.PersonalID, ExitDate: '2023-01-03' }

      before do
        enrollment.rebuild_service_history!
        enrollment.reload
      end

      it 'skips processing if already processed' do
        # Mock already_processed? to return true
        allow(enrollment).to receive(:already_processed?).and_return(true)

        result = enrollment.rebuild_service_history!
        expect(result).to be false
      end
    end

    context 'when enrollment is still open' do
      it 'creates service history through current date' do
        # No exit created, enrollment is open
        result = enrollment.rebuild_service_history!

        expect(result).to eq(:update)

        service_dates = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID },
        ).pluck(:date).sort

        expect(service_dates.first).to eq('2023-01-01'.to_date)
        expect(service_dates.last).to be <= Date.current
      end
    end
  end
end
