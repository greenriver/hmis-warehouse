###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClientSearch do
  let!(:target_client) { create(:authoritative_hud_client, FirstName: 'Zzexclude', LastName: 'Zztarget', SSN: '999887777', DOB: Date.new(1980, 5, 5)) }
  let!(:other_client) { create(:authoritative_hud_client, FirstName: 'Zzopen', LastName: 'Zzother', SSN: '111223333', DOB: Date.new(1981, 6, 6)) }

  def excluding(client)
    GrdaWarehouse::Hud::Client.arel_table[:id].not_eq(client.id)
  end

  describe '.text_searcher' do
    it 'applies the filter to an SSN match' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false, name_and_ssn_filter: excluding(target_client))

      expect(results.to_a).to eq([])
    end

    it 'keeps an SSN match the filter allows' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false, name_and_ssn_filter: excluding(other_client))

      expect(results.to_a).to eq([target_client])
    end

    it 'applies the filter to a name match' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('Zzexclude Zztarget', sorted: false, name_and_ssn_filter: excluding(target_client))

      expect(results.to_a).to eq([])
    end

    it 'ignores the filter for a DOB match' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('05/05/1980', sorted: false, name_and_ssn_filter: excluding(target_client))

      expect(results.to_a).to eq([target_client])
    end

    it 'filters nothing when the parameter is omitted' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false)

      expect(results.to_a).to eq([target_client])
    end
  end

  describe '.text_searcher with numeric Scan Card codes' do
    before { allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true) }

    let!(:id_client) { create(:hmis_hud_client) }
    let!(:personal_id_client) { create(:hmis_hud_client, personal_id: '987654321') }
    let!(:card_client) { create(:hmis_hud_client) }

    def search(text)
      Hmis::Hud::Client.text_searcher(text, sorted: false)
    end

    it 'returns both clients when a scan card code matches a client id' do
      create(:hmis_scan_card_code, client: card_client, value: id_client.id.to_s)

      expect(search(id_client.id.to_s)).to contain_exactly(id_client, card_client)
    end

    it 'returns both clients when a scan card code matches a personal id' do
      create(:hmis_scan_card_code, client: card_client, value: '987654321')

      expect(search('987654321')).to contain_exactly(personal_id_client, card_client)
    end

    it 'returns the scan card client when nothing else matches' do
      create(:hmis_scan_card_code, client: card_client, value: '9999999999')

      expect(search('9999999999')).to contain_exactly(card_client)
    end

    it 'matches a scan card code with leading zeros only on the exact value' do
      create(:hmis_scan_card_code, client: card_client, value: '00123456789')

      expect(search('00123456789')).to include(card_client)
      expect(search('123456789')).not_to include(card_client)
    end

    it 'ignores an expired scan card code' do
      create(:hmis_scan_card_code, client: card_client, value: id_client.id.to_s, expires_at: Date.current - 2.days)

      expect(search(id_client.id.to_s)).to contain_exactly(id_client)
    end

    it 'returns both clients when a scan card code matches a merged client id' do
      deleted_client = create(:hmis_hud_client)
      Hmis::ClientMergeHistory.create!(retained_client: id_client, deleted_client: deleted_client, client_merge_audit: create(:hmis_client_merge_audit, actor: create(:hmis_user)))
      deleted_client.destroy!
      create(:hmis_scan_card_code, client: card_client, value: deleted_client.id.to_s)

      expect(search(deleted_client.id.to_s)).to contain_exactly(id_client, card_client)
    end

    it 'returns both clients when a scan card code matches a warehouse destination id' do
      warehouse_client = create(:hmis_warehouse_client, source: id_client, data_source: id_client.data_source)
      create(:hmis_scan_card_code, client: card_client, value: warehouse_client.destination_id.to_s)

      expect(search(warehouse_client.destination_id.to_s)).to include(id_client, card_client)
    end

    it 'returns only the scan card client for a dashed code' do
      create(:hmis_scan_card_code, client: card_client, value: "#{id_client.id}-99")

      expect(search("#{id_client.id}-99")).to contain_exactly(card_client)
    end

    it 'returns both clients through GrdaWarehouse::Hud::Client as a join query' do
      create(:hmis_scan_card_code, client: card_client, value: id_client.id.to_s)

      results = GrdaWarehouse::Hud::Client.text_searcher(id_client.id.to_s, sorted: false, resolve_for_join_query: true)

      expect(results.map { |row| row['client_id'] }).to contain_exactly(id_client.id, card_client.id)
    end

    it 'ignores scan card codes when HMIS is disabled' do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)
      create(:hmis_scan_card_code, client: card_client, value: id_client.id.to_s)

      expect(search(id_client.id.to_s)).to contain_exactly(id_client)
    end
  end
end
