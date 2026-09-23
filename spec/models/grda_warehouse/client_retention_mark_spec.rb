###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientRetentionMark, type: :model do
  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:ds_one) { create(:source_data_source, name: 'Vendor One', short_name: 'V1') }
  let!(:ds_two) { create(:source_data_source, name: 'Vendor Two', short_name: 'V2') }

  let!(:destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, DateUpdated: 12.years.ago.to_date) }
  let!(:source_one) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 10.years.ago.to_date) }
  let!(:source_two) { create(:grda_warehouse_hud_client, data_source: ds_two, DateUpdated: 10.years.ago.to_date) }

  before do
    link(source_one)
    link(source_two)
  end

  def link(source, deleted_at: nil)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.PersonalID, deleted_at: deleted_at)
  end

  def rollup(**options)
    described_class.rollup_activity(destination_ids: [destination.id], global_years: 7, **options).find { |row| row[:destination_id] == destination.id }
  end

  def enroll(source, entry_on:, exit_on: nil, updated_at: entry_on)
    enrollment = create(:hud_enrollment, data_source_id: source.data_source_id, PersonalID: source.PersonalID, EntryDate: entry_on, DateUpdated: updated_at)
    create(:hud_exit, data_source_id: source.data_source_id, PersonalID: source.PersonalID, EnrollmentID: enrollment.EnrollmentID, ExitDate: exit_on, DateUpdated: exit_on) if exit_on
    enrollment
  end

  describe '.rollup_activity' do
    context 'when every enrollment has exited' do
      before do
        enroll(source_one, entry_on: 12.years.ago.to_date, exit_on: 9.years.ago.to_date)
        enroll(source_two, entry_on: 11.years.ago.to_date, exit_on: 8.years.ago.to_date)
      end

      it 'uses the latest exit date across the sources and reports the exited basis' do
        expect(rollup).to include(last_activity_on: 8.years.ago.to_date, basis: 'exited')
      end

      it 'ignores services, living situations and income records under exited enrollments' do
        create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, DateProvided: 1.year.ago.to_date)
        create(:hud_current_living_situation, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, InformationDate: 1.year.ago.to_date)
        create(:hud_income_benefit, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, InformationDate: 1.year.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
      end

      it 'counts an update to the source client row' do
        source_one.update_columns(DateUpdated: 1.year.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(1.year.ago.to_date)
      end

      it 'ignores a client row update dated in the future' do
        source_one.update_columns(DateUpdated: 1.year.from_now.to_date)

        expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
      end

      it 'ignores an exit dated in the future' do
        GrdaWarehouse::Hud::Exit.where(PersonalID: source_two.PersonalID).update_all(ExitDate: 1.year.from_now.to_date)

        expect(rollup[:last_activity_on]).to eq(9.years.ago.to_date)
      end

      it 'ignores a soft-deleted exit\'s enrollment date but treats the enrollment as still open' do
        enrollment = enroll(source_one, entry_on: 2.years.ago.to_date, exit_on: 1.year.ago.to_date)
        GrdaWarehouse::Hud::Exit.where(EnrollmentID: enrollment.EnrollmentID).update_all(DateDeleted: Time.current)

        expect(rollup).to include(last_activity_on: 2.years.ago.to_date, basis: 'open_enrollment')
      end

      it 'ignores a soft-deleted enrollment, so the identity stays exited' do
        enroll(source_one, entry_on: 1.year.ago.to_date).update_columns(DateDeleted: Time.current)

        expect(rollup).to include(last_activity_on: 8.years.ago.to_date, basis: 'exited')
      end
    end

    context 'when an enrollment is open' do
      let!(:open_enrollment) { enroll(source_one, entry_on: 9.years.ago.to_date) }

      before { enroll(source_two, entry_on: 11.years.ago.to_date, exit_on: 8.years.ago.to_date) }

      it 'reports the open_enrollment basis and the latest of the entry and sibling exit dates' do
        expect(rollup).to include(last_activity_on: 8.years.ago.to_date, basis: 'open_enrollment')
      end

      it 'counts a service under the open enrollment' do
        create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, DateProvided: 3.years.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(3.years.ago.to_date)
      end

      it 'ignores a service dated in the future' do
        create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, DateProvided: 1.year.from_now.to_date)

        expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
      end

      it 'counts a current living situation' do
        create(:hud_current_living_situation, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, InformationDate: 4.years.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(4.years.ago.to_date)
      end

      it 'counts an income record' do
        create(:hud_income_benefit, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, InformationDate: 5.years.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(5.years.ago.to_date)
      end

      it 'counts an update to the enrollment row' do
        open_enrollment.update_columns(DateUpdated: 2.years.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(2.years.ago.to_date)
      end

      it 'counts an update to the source client row' do
        source_two.update_columns(DateUpdated: 6.years.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(6.years.ago.to_date)
      end

      it 'counts the exit date of a sibling exited enrollment' do
        GrdaWarehouse::Hud::Exit.where(PersonalID: source_two.PersonalID).update_all(ExitDate: 1.year.ago.to_date)

        expect(rollup[:last_activity_on]).to eq(1.year.ago.to_date)
      end

      it 'ignores soft-deleted records, links and source clients' do
        create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, DateProvided: 1.day.ago.to_date, DateDeleted: Time.current)
        recent_source = create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 1.day.ago.to_date)
        link(recent_source, deleted_at: Time.current)
        deleted_source = create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 1.day.ago.to_date, DateDeleted: Time.current)
        link(deleted_source)

        expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
        expect(rollup[:source_clients].map { |sc| sc['client_id'] }).to contain_exactly(source_one.id, source_two.id)
      end

      it 'ignores soft-deleted living situation and income records' do
        create(:hud_current_living_situation, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, InformationDate: 1.day.ago.to_date, DateDeleted: Time.current)
        create(:hud_income_benefit, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EnrollmentID: open_enrollment.EnrollmentID, InformationDate: 2.days.ago.to_date, DateDeleted: Time.current)

        expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
      end

      it 'handles soft-deleted source clients properly' do
        # Soft-delete one source client while keeping warehouse_client link active
        source_two.update_columns(DateDeleted: Time.current)

        # Verify that the soft-deleted source is not included in activity calculation
        result = rollup

        # Should only include non-deleted source in the source_clients list
        expect(result[:source_clients].map { |sc| sc['client_id'] }).to contain_exactly(source_one.id)
      end
    end

    context 'when the sources have no enrollments' do
      it 'uses the client rows under the exited rule' do
        expect(rollup).to include(last_activity_on: 10.years.ago.to_date, basis: 'exited')
      end

      it 'returns no row when no source has an activity date' do
        GrdaWarehouse::Hud::Client.where(id: [source_one.id, source_two.id]).update_all(DateUpdated: nil)

        expect(rollup).to be_nil
      end
    end

    it 'uses the longest window across the sources, each falling back to the global window' do
      ds_two.update!(client_retention_years: 10)

      expect(rollup[:retention_years]).to eq(10)
    end

    it 'lists each source with its data source and PersonalID but no name' do
      expect(rollup[:source_clients]).to contain_exactly(
        { 'client_id' => source_one.id, 'data_source_id' => ds_one.id, 'personal_id' => source_one.PersonalID },
        { 'client_id' => source_two.id, 'data_source_id' => ds_two.id, 'personal_id' => source_two.PersonalID },
      )
    end
  end
end
