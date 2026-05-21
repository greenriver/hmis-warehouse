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
      it 'processes successfully when all guard conditions pass' do
        result = enrollment.rebuild_service_history!
        expect(result).to eq(:update)
        expect(GrdaWarehouse::ServiceHistoryEnrollment.where(enrollment_group_id: enrollment.EnrollmentID).exists?).to be true
      end

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
        expect(service_dates.last).to eq Date.current
      end
    end
  end

  describe '#rebuild_service_history! for SO enrollments with extrapolation' do
    # SO = project_type 4. street_outreach_acts_as_bednight? returns true when the project
    # has any enrollment with current_living_situations (detected via EXISTS join). We stub
    # the config and the predicate directly to keep tests fast and deterministic.
    let(:project) { create :grda_warehouse_hud_project, data_source: data_source, organization: organization, project_type: 4 }
    let!(:client) { create_client_with_warehouse_link(dob: '1990-01-01') }

    before do
      allow(GrdaWarehouse::Config).to receive(:get).and_call_original
      allow(GrdaWarehouse::Config).to receive(:get).with(:so_day_as_month).and_return(true)
    end

    context 'with a closed enrollment' do
      let(:enrollment) do
        en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-10'
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
      end
      let!(:cls_jan10) do
        create :hud_current_living_situation,
               data_source_id: data_source.id,
               EnrollmentID: enrollment.EnrollmentID,
               PersonalID: client.PersonalID,
               InformationDate: '2023-01-10'
      end
      let!(:exit_record) do
        create :hud_exit, data_source_id: data_source.id,
                          EnrollmentID: enrollment.EnrollmentID,
                          PersonalID: client.PersonalID,
                          ExitDate: '2023-01-31'
      end

      it 'first run triggers a full rebuild and writes extrapolated days' do
        result = enrollment.rebuild_service_history!
        expect(result).to eq(:update)

        shs_scope = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
          where(service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID })

        expect(shs_scope.where(record_type: 'service').count).to eq(1)
        expect(shs_scope.where(record_type: 'extrapolated').count).to be > 0
      end

      it 'second run with no source changes is a no-op' do
        enrollment.rebuild_service_history!

        initial_count = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
          where(service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID }).count

        fresh = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment.id)
        hash_before = fresh.processed_as
        second_result = fresh.rebuild_service_history!

        expect(second_result).to be_nil
        expect(fresh.reload.processed_as).to eq(hash_before)

        final_count = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
          where(service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID }).count

        expect(final_count).to eq(initial_count)
      end

      it 'new CLS contact triggers a full rebuild via hash mismatch' do
        enrollment.rebuild_service_history!

        create :hud_current_living_situation,
               data_source_id: data_source.id,
               EnrollmentID: enrollment.EnrollmentID,
               PersonalID: client.PersonalID,
               InformationDate: '2023-01-20'

        result = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment.id).rebuild_service_history!
        expect(result).to eq(:update)

        service_dates = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).where(
          service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID },
          record_type: 'service',
        ).pluck(:date)

        expect(service_dates).to include('2023-01-10'.to_date, '2023-01-20'.to_date)
      end
    end

    context 'with an open enrollment (no exit)' do
      let(:enrollment) do
        en = create :grda_warehouse_hud_enrollment, data_source: data_source, project: project, client: client, entry_date: '2023-01-10'
        GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(en.id)
      end
      let!(:cls_jan10) do
        create :hud_current_living_situation,
               data_source_id: data_source.id,
               EnrollmentID: enrollment.EnrollmentID,
               PersonalID: client.PersonalID,
               InformationDate: '2023-01-10'
      end

      it 'patches new extrapolated days on subsequent runs as the calendar advances' do
        travel_to Date.new(2023, 1, 15) do
          enrollment.rebuild_service_history!
        end

        extrapolated_jan15 = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
          where(service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID },
                record_type: 'extrapolated').pluck(:date)
        expect(extrapolated_jan15).not_to include(Date.new(2023, 1, 16))
        expect(extrapolated_jan15).to include(Date.new(2023, 1, 15))

        result = travel_to Date.new(2023, 1, 16) do
          GrdaWarehouse::Tasks::ServiceHistory::Enrollment.find(enrollment.id).rebuild_service_history!
        end

        expect(result).to eq(:patch)

        extrapolated_jan16 = GrdaWarehouse::ServiceHistoryService.joins(:service_history_enrollment).
          where(service_history_enrollments: { enrollment_group_id: enrollment.EnrollmentID },
                record_type: 'extrapolated').pluck(:date)
        expect(extrapolated_jan16).to include(Date.new(2023, 1, 15))
        expect(extrapolated_jan16).to include(Date.new(2023, 1, 16))
      end
    end
  end
end
