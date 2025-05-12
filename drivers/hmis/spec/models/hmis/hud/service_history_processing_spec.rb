###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'ServiceHistory processing', type: :model do
  include_context 'hmis base setup'

  context 'Enrollment fields' do
    let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
    let!(:enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: p1, client: client, entry_date: 1.month.ago) }

    before(:each) do
      enrollment.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
      Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').delete_all
    end

    context 'for open Enrollment' do
      [
        # fields that SHOULD trigger re-processing
        ['EntryDate', 1.week.ago],
        ['MoveInDate', 1.week.ago],
        ['RelationshipToHoH', 99],
        ['LivingSituation', 101],
        ['HouseholdID', 'newhouseholdid'],
        ['DateDeleted', Time.current],
      ].each do |field, value|
        it "change to Enrollment.#{field} triggers service history processing" do
          enrollment.assign_attributes(field => value)

          expect do
            enrollment.save!
            enrollment.reload
          end.to change { enrollment.processed_as }.from('PROCESSED').to(nil).
            and change { enrollment.processed_hash }.from('PROCESSED').to(nil).
            and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)
        end
      end

      [
        # fields that should NOT trigger re-processing
        ['DateOfEngagement', 1.week.ago],
        ['DisablingCondition', 8],
      ].each do |field, value|
        it "change to Enrollment.#{field} does not triggers service history processing" do
          enrollment.assign_attributes(field => value)

          expect do
            enrollment.save!
            enrollment.reload
          end.to not_change { enrollment.processed_as }.
            and not_change { enrollment.processed_hash }.
            and not_change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count)
        end
      end
    end

    context 'for WIP Enrollment' do
      let!(:enrollment) { create(:hmis_hud_wip_enrollment, data_source: ds1, project: p1, client: client) }

      it 'saving as non-WIP triggers service history processing' do
        expect do
          enrollment.save_not_in_progress!
          enrollment.reload
        end.to change { enrollment.processed_as }.from('PROCESSED').to(nil).
          and change { enrollment.processed_hash }.from('PROCESSED').to(nil).
          and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)
      end
    end

    context 'for Exited Enrollment' do
      let!(:exit_record) { create(:hmis_hud_exit, data_source: ds1, enrollment: enrollment, client: client, exit_date: 2.days.ago) }

      before(:each) do
        enrollment.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
        Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').delete_all
      end

      [
        ['ExitDate', 1.week.ago],
        ['Destination', 30], # no exit interview
        ['HousingAssessment', 2], # Moved to new housing unit
        ['DateDeleted', Time.current],
      ].each do |field, value|
        it "change to Exit.#{field} triggers service history processing" do
          exit_record.assign_attributes(field => value)

          expect do
            exit_record.save!
            exit_record.reload
          end.to change { enrollment.processed_as }.from('PROCESSED').to(nil).
            and change { enrollment.processed_hash }.from('PROCESSED').to(nil).
            and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)
        end
      end
    end

    context 'for CurrentLivingSituation' do
      let!(:current_living_situation) { create(:hmis_current_living_situation, data_source: ds1, enrollment: enrollment, client: client, information_date: 1.week.ago) }

      before(:each) do
        enrollment.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
        Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').delete_all
      end

      [
        ['InformationDate', 1.day.ago],
        ['DateDeleted', Time.current],
      ].each do |field, value|
        it "change to #{field} triggers service history processing" do
          current_living_situation.assign_attributes(field => value)

          expect do
            current_living_situation.save!
            current_living_situation.reload
          end.to change { enrollment.processed_as }.from('PROCESSED').to(nil).
            and change { enrollment.processed_hash }.from('PROCESSED').to(nil).
            and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)
        end
      end
    end

    context 'for Service' do
      let!(:service) { create(:hmis_hud_service, data_source: ds1, enrollment: enrollment, client: client, date_provided: 1.week.ago) }

      before(:each) do
        enrollment.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
        Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').delete_all
      end

      [
        ['DateProvided', 1.day.ago],
        ['RecordType', 141],
        ['TypeProvided', 2],
        ['DateDeleted', Time.current],
      ].each do |field, value|
        it "change to #{field} triggers service history processing" do
          service.assign_attributes(field => value)

          expect do
            service.save!(validate: false) # ignore invalid TypeProvided/RecordType combo
            service.reload
          end.to change { enrollment.processed_as }.from('PROCESSED').to(nil).
            and change { enrollment.processed_hash }.from('PROCESSED').to(nil).
            and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)
        end
      end
    end
  end
end
