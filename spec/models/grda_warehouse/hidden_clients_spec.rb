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
  # A restriction placed on a destination row itself, so the source under it is hidden only through its destination.
  let!(:directly_restricted_destination) { create(:grda_warehouse_hud_client) }
  let!(:source_under_restricted_destination) { create(:hmis_hud_client, data_source: hmis_ds) }

  before do
    link(restricted_destination, restricted_source)
    link(restricted_destination, sibling_source)
    link(inactive_destination, inactive_source)
    restricted_source.mark_as_restricted!(user: hmis_user)
    unmerged_restricted.mark_as_restricted!(user: hmis_user)
    mark_inactive(inactive_source)
    link(directly_restricted_destination, source_under_restricted_destination)
    Hmis::RestrictedRecord.create!(restrictable_id: directly_restricted_destination.id, restrictable_type: Hmis::RestrictedRecord::CLIENT_RESTRICTABLE_TYPE, data_source_id: directly_restricted_destination.data_source_id, created_by: hmis_user)
  end

  def link(destination, source, deleted_at: nil)
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination.id, source_id: source.id, data_source_id: source.data_source_id, id_in_source: source.id.to_s, deleted_at: deleted_at)
  end

  def mark_inactive(client)
    GrdaWarehouse::ClientRetentionMark.create!(client_id: client.id, marked_on: Date.current, last_activity_on: 10.years.ago.to_date, retention_years: 7)
  end

  def visible_ids
    GrdaWarehouse::Hud::Client.where(described_class.not_hidden(GrdaWarehouse::Hud::Client.arel_table[:id])).pluck(:id)
  end

  describe '.hidden_ids_in' do
    it 'matches restricted_subset and inactive_subset for every client in the table' do
      all_ids = GrdaWarehouse::Hud::Client.pluck(:id)

      expect(described_class.hidden_ids_in(GrdaWarehouse::Hud::Client.all)).
        to eq(described_class.restricted_subset(all_ids) | described_class.inactive_subset(all_ids))
    end

    it 'returns only hidden ids inside the given scope' do
      scope = GrdaWarehouse::Hud::Client.where(id: [restricted_destination.id, inactive_destination.id, open_client.id])

      expect(described_class.hidden_ids_in(scope)).to eq(Set[restricted_destination.id, inactive_destination.id])
    end
  end

  describe '.inactive_subset' do
    it 'returns only the given ids that are inactive, for a source id and a destination id alike' do
      asked = [inactive_source.id, inactive_destination.id, open_client.id, restricted_source.id]

      expect(described_class.inactive_subset(asked)).to eq(Set[inactive_source.id, inactive_destination.id])
    end

    it 'does not reach a destination through a soft-deleted link' do
      GrdaWarehouse::WarehouseClient.where(source_id: inactive_source.id).update_all(deleted_at: Time.current)

      expect(described_class.inactive_subset([inactive_source.id, inactive_destination.id])).to eq(Set[inactive_source.id])
    end

    it 'returns an empty set for no ids without querying' do
      expect(GrdaWarehouseBase.connection).not_to receive(:select_values)

      expect(described_class.inactive_subset([])).to eq(Set.new)
    end
  end

  describe '.restricted_subset' do
    it 'returns the restricted members of the given ids across source, destination, sibling, and unmerged clients' do
      asked = [restricted_source.id, restricted_destination.id, sibling_source.id, unmerged_restricted.id, inactive_source.id, open_client.id]

      expect(described_class.restricted_subset(asked)).to eq(Set[restricted_source.id, restricted_destination.id, sibling_source.id, unmerged_restricted.id])
    end

    it 'hides the source under a directly restricted destination' do
      expect(described_class.restricted_subset([source_under_restricted_destination.id])).to eq(Set[source_under_restricted_destination.id])
    end

    it 'hides a destination and a sibling source when the restricted source is not among the given ids' do
      expect(described_class.restricted_subset([restricted_destination.id, sibling_source.id])).
        to eq(Set[restricted_destination.id, sibling_source.id])
    end

    it 'does not spread a restriction through a soft-deleted merge link' do
      detached_source = create(:hmis_hud_client, data_source: hmis_ds)
      link(restricted_destination, detached_source, deleted_at: Time.current)

      expect(described_class.restricted_subset([detached_source.id])).to eq(Set.new)
    end

    it 'returns an empty set for no ids without querying' do
      expect(count_database_queries { described_class.restricted_subset([nil]) }).to eq(0)
    end

    it 'runs one query when given the identity links' do
      links = described_class.identity_links([restricted_destination.id])

      expect(count_database_queries { described_class.restricted_subset([restricted_destination.id], identity_links: links) }).to eq(1)
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

    it 'agrees with restricted_subset and inactive_subset for every client in the table' do
      all_ids = GrdaWarehouse::Hud::Client.pluck(:id)
      hidden = described_class.restricted_subset(all_ids) | described_class.inactive_subset(all_ids)

      expect(visible_ids).to match_array(all_ids - hidden.to_a)
    end

    it 'keeps a row whose correlated column is NULL' do
      expect(GrdaWarehouse::Hud::Client.where(described_class.not_hidden(Arel.sql('NULL::bigint'))).count).to eq(GrdaWarehouse::Hud::Client.count)
    end
  end
end
