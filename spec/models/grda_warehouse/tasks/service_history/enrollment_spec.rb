###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ServiceHistory::Enrollment, type: :model do
  let(:data_source) { create :grda_warehouse_data_source }
  let(:organization) { create :hud_organization, data_source: data_source }

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
end
