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
end
