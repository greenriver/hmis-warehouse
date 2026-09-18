###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::ClientRetentionDryRun, type: :model do
  let!(:warehouse_ds) { create(:destination_data_source) }
  let!(:ds_one) { create(:source_data_source) }
  let!(:exited_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds) }
  let!(:exited_source) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 10.years.ago.to_date) }
  let!(:open_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds) }
  let!(:open_source) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 1.year.ago.to_date) }
  let!(:bare_destination) { create(:grda_warehouse_hud_client, data_source: warehouse_ds) }
  let!(:bare_source) { create(:grda_warehouse_hud_client, data_source: ds_one, DateUpdated: 10.years.ago.to_date) }

  before do
    [[exited_destination, exited_source], [open_destination, open_source], [bare_destination, bare_source]].each do |destination, source|
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: ds_one.id, id_in_source: source.PersonalID)
    end
    exited = create(:hud_enrollment, data_source_id: ds_one.id, PersonalID: exited_source.PersonalID, EntryDate: 12.years.ago.to_date)
    create(:hud_exit, data_source_id: ds_one.id, PersonalID: exited_source.PersonalID, EnrollmentID: exited.EnrollmentID, ExitDate: 9.years.ago.to_date)
    create(:hud_enrollment, data_source_id: ds_one.id, PersonalID: open_source.PersonalID, EntryDate: 2.years.ago.to_date)
  end

  subject(:summary) { described_class.new(global_years: 7, batch_size: 2).run }

  it 'counts evaluated identities by basis' do
    expect(summary[:evaluated_by_basis]).to eq('exited' => 2, 'open_enrollment' => 1)
  end

  it 'counts the identities that would be marked, by basis, and lists a sample of them' do
    expect(summary[:would_mark_by_basis]).to eq('exited' => 2)
    expect(summary[:sample_destination_ids]).to contain_exactly(exited_destination.id, bare_destination.id)
  end

  it 'reports batch count and timings' do
    expect(summary[:batches]).to eq(2)
    expect(summary[:elapsed_seconds]).to be_a(Float)
    expect(summary[:slowest_batch_seconds]).to be <= summary[:elapsed_seconds]
  end

  it 'writes nothing' do
    expect { summary }.not_to(change { [GrdaWarehouse::InactiveClient.count, GrdaWarehouse::ClientRetentionRun.count, GrdaWarehouse::ClientRetentionLogEntry.count] })
  end

  it 'stops after the limit' do
    limited = described_class.new(global_years: 7, batch_size: 2, limit: 2).run

    expect(limited[:destinations]).to eq(2)
  end

  it 'returns planner output for one batch without writing' do
    expect(described_class.new(global_years: 7).explain).to include('Planning Time', 'Execution Time')
  end
end
