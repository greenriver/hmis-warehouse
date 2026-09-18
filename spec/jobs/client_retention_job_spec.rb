###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientRetentionJob, type: :job do
  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:ds_one) { create(:source_data_source, name: 'Vendor One', short_name: 'V1') }
  let!(:ds_two) { create(:source_data_source, name: 'Vendor Two', short_name: 'V2') }

  let!(:destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, DateUpdated: 12.years.ago) }
  let!(:source_one) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 8.years.ago) }
  let!(:source_two) { create(:grda_warehouse_hud_client, data_source: ds_two, DateUpdated: 8.years.ago) }

  # An identity nobody should touch: exited last year.
  let!(:active_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds, DateUpdated: 1.year.ago) }
  let!(:active_source) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 1.year.ago) }

  before do
    link(destination, source_one)
    link(destination, source_two)
    link(active_destination, active_source)
    Rails.cache.clear
  end

  after { GrdaWarehouse::Config.invalidate_cache }

  def link(destination, source)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.PersonalID)
  end

  def configure_global_retention(years)
    GrdaWarehouse::Config.first_or_create.update!(client_retention_years: years)
    GrdaWarehouse::Config.invalidate_cache
  end

  def marked_ids
    GrdaWarehouse::InactiveClient.pluck(:client_id)
  end

  context 'when retention is disabled' do
    before { configure_global_retention(nil) }

    it 'marks nothing and records no run' do
      described_class.perform_now

      expect(marked_ids).to be_empty
      expect(GrdaWarehouse::ClientRetentionRun.count).to eq(0)
    end
  end

  context 'with a seven-year global window' do
    before { configure_global_retention(7) }

    it 'marks each source of the aged-out identity, never the destination, and leaves the active identity alone' do
      described_class.perform_now

      expect(marked_ids).to contain_exactly(source_one.id, source_two.id)
      mark = GrdaWarehouse::InactiveClient.find_by(client_id: source_two.id)
      expect(mark.last_activity_on).to eq(8.years.ago.to_date)
      expect(mark.retention_years).to eq(7)
    end

    it 'logs the mark with source identifiers and counts, and never a name' do
      described_class.perform_now

      run = GrdaWarehouse::ClientRetentionRun.completed.sole
      expect(run.global_retention_years).to eq(7)
      expect(run.evaluated_count).to eq(2)
      expect(run.marked_count).to eq(1)
      expect(run.unmarked_count).to eq(0)

      entry = run.log_entries.sole
      expect(entry.action).to eq('marked')
      expect(entry.destination_client_id).to eq(destination.id)
      expect(entry.source_clients.map { |sc| sc['client_id'] }).to contain_exactly(source_one.id, source_two.id)
      expect(entry.source_clients.flat_map(&:keys).uniq).to contain_exactly('client_id', 'data_source_id', 'personal_id')
      expect(entry.attributes.to_json).not_to include(destination.FirstName)
    end

    it 'keeps an identity whose newest activity is exactly at the window edge' do
      source_one.update!(DateUpdated: 7.years.ago)

      described_class.perform_now

      expect(marked_ids).to be_empty
    end

    it 'clears the mark and logs an unmark once the identity has fresh activity' do
      described_class.perform_now
      create(:hud_service, data_source_id: ds_one.id, PersonalID: source_one.PersonalID, DateProvided: Date.current, DateUpdated: Time.current)

      described_class.perform_now

      expect(marked_ids).to be_empty
      second_run = GrdaWarehouse::ClientRetentionRun.order(:id).last
      expect(second_run.unmarked_count).to eq(1)
      expect(second_run.log_entries.sole.action).to eq('unmarked')
    end

    it 'does not re-log an identity that stays marked, and adds a row for a newly merged source' do
      described_class.perform_now
      late_source = create(:grda_warehouse_hud_client, data_source: ds_two, DateUpdated: 9.years.ago)
      link(destination, late_source)

      described_class.perform_now

      expect(marked_ids).to contain_exactly(source_one.id, source_two.id, late_source.id)
      expect(GrdaWarehouse::ClientRetentionLogEntry.where(destination_client_id: destination.id).count).to eq(1)
    end

    it 'leaves a mark in place when its source loses its warehouse_clients link' do
      described_class.perform_now
      GrdaWarehouse::WarehouseClient.where(source_id: source_two.id).delete_all

      described_class.perform_now

      expect(marked_ids).to contain_exactly(source_one.id, source_two.id)
      expect(GrdaWarehouse::ClientRetentionLogEntry.where(destination_client_id: destination.id).count).to eq(1)
    end

    it 'clears the mark of a source that moves into an active identity and logs the unmark against that identity' do
      described_class.perform_now
      GrdaWarehouse::WarehouseClient.where(source_id: source_two.id).delete_all
      link(active_destination, source_two)

      described_class.perform_now

      expect(marked_ids).to contain_exactly(source_one.id)
      entry = GrdaWarehouse::ClientRetentionLogEntry.where(action: 'unmarked').sole
      expect(entry.destination_client_id).to eq(active_destination.id)
      expect(entry.source_clients.map { |sc| sc['client_id'] }).to contain_exactly(active_source.id, source_two.id)
    end

    it 'keeps the identity when one of its data sources has a longer window' do
      ds_two.update!(client_retention_years: 10)

      described_class.perform_now

      expect(marked_ids).to be_empty
      expect(GrdaWarehouse::ClientRetentionRun.sole.data_source_overrides).to eq(ds_two.id.to_s => 10)
    end
  end

  context 'with a ten-year global window and a shorter override on one source' do
    before do
      configure_global_retention(10)
      ds_one.update!(client_retention_years: 7)
    end

    it 'does not shorten the window for an identity that also has records under the global window' do
      described_class.perform_now

      expect(marked_ids).to be_empty
    end

    it 'ages out an identity present only in the shorter data source at that source\'s window' do
      GrdaWarehouse::WarehouseClient.where(source_id: source_two.id).delete_all

      described_class.perform_now

      expect(marked_ids).to contain_exactly(source_one.id)
      expect(GrdaWarehouse::InactiveClient.find_by(client_id: source_one.id).retention_years).to eq(7)
    end
  end
end
