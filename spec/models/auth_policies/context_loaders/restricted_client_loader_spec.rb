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

    it 'issues zero queries for a nil id, and does not load until the first real lookup' do
      expect(GrdaWarehouse::HiddenClients).not_to receive(:restricted_ids)
      loader.restricted?(nil)
    end

    it 'issues a fixed number of queries for preloaded ids regardless of how many are asked about' do
      source_client.mark_as_restricted!(user: hmis_user)
      other_ids = Array.new(12) { create(:grda_warehouse_hud_client).id }

      query_count = 0
      # Column-definition loads for a model's first use are not lookups.
      callback = ->(*args) { query_count += 1 unless args.last[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        loader.preload([destination_client.id] + other_ids)
        loader.restricted?(destination_client.id)
        other_ids.each { |id| loader.restricted?(id) }
      end

      # one for the restricted set, one for the preloaded inactive lookups
      expect(query_count).to eq(2)
    end
  end

  describe 'retention-inactive clients' do
    def mark_inactive(client_id)
      GrdaWarehouse::ClientRetentionMark.create!(client_id: client_id, marked_on: Date.current, last_activity_on: 10.years.ago.to_date, retention_years: 7)
    end

    it 'treats an id in client_retention_marks as restricted' do
      mark_inactive(source_client.id)

      expect(loader.restricted?(source_client.id)).to eq(true)
    end

    it 'hides the destination of a marked source through its live warehouse_clients link' do
      mark_inactive(source_client.id)

      expect(loader.restricted?(destination_client.id)).to eq(true)
    end

    it 'does not hide a destination whose only link to a marked source is soft-deleted' do
      mark_inactive(source_client.id)
      GrdaWarehouse::WarehouseClient.where(source_id: source_client.id).update_all(deleted_at: Time.current)

      expect(loader.restricted?(destination_client.id)).to eq(false)
    end

    it 'answers a second lookup for the same id without another query' do
      mark_inactive(source_client.id)
      loader.restricted?(source_client.id)

      query_count = 0
      callback = ->(*args) { query_count += 1 unless args.last[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        loader.restricted?(source_client.id)
      end

      expect(query_count).to eq(0)
    end

    it 'answers preloaded ids, marked and unmarked alike, without further queries' do
      marked_source = create(:grda_warehouse_hud_client)
      marked_destination = create(:grda_warehouse_hud_client)
      GrdaWarehouse::WarehouseClient.create!(destination_id: marked_destination.id, source_id: marked_source.id, data_source_id: marked_source.data_source_id, id_in_source: marked_source.id.to_s)
      mark_inactive(marked_source.id)
      open_ids = Array.new(3) { create(:grda_warehouse_hud_client).id }
      asked = [marked_source.id, marked_destination.id] + open_ids

      loader.preload(asked)
      loader.restricted_client_ids
      query_count = 0
      callback = ->(*args) { query_count += 1 unless args.last[:name] == 'SCHEMA' }
      answers = ActiveSupport::Notifications.subscribed(callback, 'sql.active_record') do
        asked.index_with { |id| loader.restricted?(id) }
      end

      expect(answers).to eq({ marked_source.id => true, marked_destination.id => true }.merge(open_ids.index_with { false }))
      expect(query_count).to eq(0)
    end

    it 'changes the cache token once a retention run completes' do
      before_run = loader.cache_token
      GrdaWarehouse::ClientRetentionRun.create!(started_at: 1.minute.ago, completed_at: Time.current, global_retention_years: 7)

      expect(described_class.new.cache_token).not_to eq(before_run)
    end
  end
end
