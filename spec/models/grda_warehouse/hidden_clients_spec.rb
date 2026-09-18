###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::HiddenClients, type: :model do
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:restricted_source) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:restricted_destination) { create(:grda_warehouse_hud_client) }
  let!(:sibling_source) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:unmerged_restricted) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:inactive_source) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:inactive_destination) { create(:grda_warehouse_hud_client) }
  let!(:open_client) { create(:grda_warehouse_hud_client) }

  before do
    link(restricted_destination, restricted_source)
    link(restricted_destination, sibling_source)
    link(inactive_destination, inactive_source)
    restricted_source.mark_as_restricted!(user: hmis_user)
    unmerged_restricted.mark_as_restricted!(user: hmis_user)
    mark_inactive(inactive_source)
  end

  def link(destination, source, deleted_at: nil)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.id.to_s, deleted_at: deleted_at)
  end

  def mark_inactive(client)
    GrdaWarehouse::InactiveClient.create!(client_id: client.id, marked_on: Date.current, last_activity_on: 10.years.ago.to_date, retention_years: 7)
  end

  def visible_ids
    GrdaWarehouse::Hud::Client.where(described_class.not_hidden(GrdaWarehouse::Hud::Client.arel_table[:id])).pluck(:id)
  end

  describe '.restricted_ids' do
    it 'returns the directly restricted ids, their destinations, and every source under those destinations' do
      expect(described_class.restricted_ids).to contain_exactly(restricted_source.id, restricted_destination.id, sibling_source.id, unmerged_restricted.id)
    end
  end

  describe '.inactive_ids' do
    it 'returns the marked sources and the destinations they are linked to' do
      expect(described_class.inactive_ids).to contain_exactly(inactive_source.id, inactive_destination.id)
    end

    it 'does not reach a destination through a soft-deleted link' do
      GrdaWarehouse::WarehouseClient.where(source_id: inactive_source.id).update_all(deleted_at: Time.current)

      expect(described_class.inactive_ids).to contain_exactly(inactive_source.id)
    end
  end

  describe '.inactive_destination_ids' do
    it 'returns the destinations of marked sources and not the sources themselves' do
      expect(described_class.inactive_destination_ids).to eq(Set[inactive_destination.id])
    end
  end

  describe '.inactive_subset' do
    it 'returns only the given ids that are inactive, for a source id and a destination id alike' do
      asked = [inactive_source.id, inactive_destination.id, open_client.id, restricted_source.id]

      expect(described_class.inactive_subset(asked)).to eq(Set[inactive_source.id, inactive_destination.id])
    end

    it 'returns an empty set for no ids without querying' do
      expect(GrdaWarehouseBase.connection).not_to receive(:select_values)

      expect(described_class.inactive_subset([])).to eq(Set.new)
    end
  end

  describe '.not_hidden' do
    it 'keeps only clients that are neither in a restricted identity nor in an inactive identity' do
      expect(visible_ids).to contain_exactly(open_client.id)
    end

    it 'does not spread a restriction through a soft-deleted merge link' do
      detached_source = create(:hmis_hud_client, data_source: hmis_ds)
      link(restricted_destination, detached_source, deleted_at: Time.current)

      expect(visible_ids).to contain_exactly(open_client.id, detached_source.id)
    end

    it 'keeps a row whose correlated column is NULL' do
      expect(GrdaWarehouse::Hud::Client.where(described_class.not_hidden(Arel.sql('NULL::bigint'))).count).to eq(GrdaWarehouse::Hud::Client.count)
    end
  end
end
