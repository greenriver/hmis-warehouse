###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::InactiveClient, type: :model do
  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:ds_one) { create(:source_data_source, name: 'Vendor One', short_name: 'V1') }
  let!(:ds_two) { create(:source_data_source, name: 'Vendor Two', short_name: 'V2') }

  let!(:destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, DateUpdated: 12.years.ago) }
  let!(:source_one) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 10.years.ago) }
  let!(:source_two) { create(:grda_warehouse_hud_client, data_source: ds_two, DateUpdated: 10.years.ago) }

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

  describe '.rollup_activity' do
    it 'reports the newest activity across both sources, taking the later of record date and DateUpdated' do
      create(:hud_enrollment, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EntryDate: 9.years.ago.to_date, DateUpdated: 9.years.ago)
      create(:hud_exit, data_source_id: ds_two.id, PersonalID: source_two.PersonalID, ExitDate: 9.years.ago.to_date, DateUpdated: 8.years.ago)

      expect(rollup[:last_activity_on]).to eq(8.years.ago.to_date)
    end

    it 'ignores soft-deleted HUD records and links' do
      create(:hud_enrollment, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, EntryDate: 1.day.ago.to_date, DateDeleted: Time.current)
      recent_source = create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 1.day.ago)
      link(recent_source, deleted_at: Time.current)

      expect(rollup[:last_activity_on]).to eq(10.years.ago.to_date)
      expect(rollup[:source_clients].map { |sc| sc['client_id'] }).to contain_exactly(source_one.id, source_two.id)
    end

    it 'ignores files and notes attached to the destination client' do
      create(:client_file, client: destination, created_at: 2.years.ago)
      create(:grda_warehouse_client_notes_window_note, client: destination, created_at: 1.year.ago)

      expect(rollup[:last_activity_on]).to eq(10.years.ago.to_date)
    end

    it 'counts HMIS custom services and alerts on a source client as activity' do
      hmis_ds = create(:hmis_data_source)
      hmis_client = create(:hmis_hud_client, data_source: hmis_ds)
      link(hmis_client)
      enrollment = create(:hmis_hud_enrollment, data_source: hmis_ds, client: hmis_client, EntryDate: 10.years.ago.to_date)
      service = create(:hmis_custom_service, data_source: hmis_ds, client: hmis_client, enrollment: enrollment, DateProvided: 5.years.ago.to_date)
      create(:hmis_client_alert, client: hmis_client, created_by: create(:hmis_user, data_source: hmis_ds), created_at: 3.years.ago)
      # HMIS models stamp DateCreated and DateUpdated on save, so backdate the fixtures after creation.
      [hmis_client, enrollment, service].each { |record| record.update_columns(DateCreated: 10.years.ago, DateUpdated: 10.years.ago) }

      expect(rollup[:last_activity_on]).to eq(3.years.ago.to_date)
    end

    it 'uses the longest window across the sources, each falling back to the global window' do
      ds_two.update!(client_retention_years: 10)

      expect(rollup[:retention_years]).to eq(10)
    end

    it 'uses the global window when no source has an override' do
      expect(rollup[:retention_years]).to eq(7)
    end

    it 'lists each source with its data source and PersonalID but no name' do
      expect(rollup[:source_clients]).to contain_exactly(
        { 'client_id' => source_one.id, 'data_source_id' => ds_one.id, 'personal_id' => source_one.PersonalID },
        { 'client_id' => source_two.id, 'data_source_id' => ds_two.id, 'personal_id' => source_two.PersonalID },
      )
    end

    it 'limits to rollups whose window ends within the given days when expiring_within is set' do
      # Global 7 years, newest activity 10 years ago: this rollup expired 3 years ago.
      expect(rollup(expiring_within: 90)).to be_nil

      create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, DateProvided: (7.years.ago + 30.days).to_date, DateUpdated: 8.years.ago)
      expect(rollup(expiring_within: 90)[:destination_id]).to eq(destination.id)
      expect(rollup(expiring_within: 10)).to be_nil
    end

    it 'evaluates every linked destination when destination_ids is nil' do
      rows = described_class.rollup_activity(destination_ids: nil, global_years: 7)

      expect(rows.map { |row| row[:destination_id] }).to include(destination.id)
    end
  end
end
