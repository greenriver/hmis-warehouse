###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::AuthPolicies::ContextLoaders::RestrictedClientLoader, type: :model do
  let(:loader) { described_class.new }
  let!(:hmis_ds) { create(:hmis_primary_data_source) }
  let!(:hmis_user) { create(:hmis_user, data_source: hmis_ds) }
  let!(:source_client) { create(:hmis_hud_client, data_source: hmis_ds) }
  let!(:destination_client) { create(:grda_warehouse_hud_client) }

  before do
    GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: source_client.id, data_source_id: hmis_ds.id, id_in_source: source_client.id.to_s)
  end

  describe '#restricted?' do
    it 'returns false for an unrestricted client' do
      expect(loader.restricted?(destination_client.id)).to eq(false)
    end

    it 'returns true for a restricted source client id' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(loader.restricted?(source_client.id)).to eq(true)
    end

    it 'returns true for that client\'s destination id' do
      source_client.mark_as_restricted!(user: hmis_user)
      expect(loader.restricted?(destination_client.id)).to eq(true)
    end

    it 'returns true for a sibling source client of the same destination' do
      sibling_source_client = create(:hmis_hud_client, data_source: hmis_ds)
      GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: sibling_source_client.id, data_source_id: hmis_ds.id, id_in_source: sibling_source_client.id.to_s)
      source_client.mark_as_restricted!(user: hmis_user)

      expect(loader.restricted?(sibling_source_client.id)).to eq(true)
    end

    it 'returns true for a restricted unmerged source client with no warehouse_clients row' do
      unmerged_source_client = create(:hmis_hud_client, data_source: hmis_ds)
      unmerged_source_client.mark_as_restricted!(user: hmis_user)

      expect(loader.restricted?(unmerged_source_client.id)).to eq(true)
    end

    it 'returns false after the restriction is removed' do
      source_client.mark_as_restricted!(user: hmis_user)
      source_client.remove_restriction!

      expect(loader.restricted?(destination_client.id)).to eq(false)
    end

    it 'is not restricted when the only link to a restricted destination is a soft-deleted warehouse_clients row' do
      other_source_client = create(:hmis_hud_client, data_source: hmis_ds)
      link = GrdaWarehouse::WarehouseClient.create!(destination_id: destination_client.id, source_id: other_source_client.id, data_source_id: hmis_ds.id, id_in_source: other_source_client.id.to_s)
      link.update!(deleted_at: Time.current)
      source_client.mark_as_restricted!(user: hmis_user)

      expect(loader.restricted?(other_source_client.id)).to eq(false)
    end

    it 'returns true for a destination client that is itself restricted directly' do
      Hmis::RestrictedRecord.create!(
        restrictable_id: destination_client.id,
        restrictable_type: 'Hmis::Hud::Client',
        data_source_id: destination_client.data_source_id,
        created_by: hmis_user,
      )

      expect(loader.restricted?(destination_client.id)).to eq(true)
    end

    it 'returns false for a nil id' do
      expect(loader.restricted?(nil)).to eq(false)
    end

    it 'issues zero queries for a nil id, and does not load until the first real lookup' do
      expect(Hmis::RestrictedRecord).not_to receive(:for_clients)
      loader.restricted?(nil)
    end

    it 'issues a fixed number of queries regardless of how many ids are asked about' do
      source_client.mark_as_restricted!(user: hmis_user)
      other_ids = Array.new(12) { create(:grda_warehouse_hud_client).id }

      query_count = 0
      callback = ->(*, **) { query_count += 1 }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        loader.restricted?(destination_client.id)
        other_ids.each { |id| loader.restricted?(id) }
      end

      expect(query_count).to eq(3)
    end
  end
end
