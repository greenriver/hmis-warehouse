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

  describe '.text_searcher' do
    it 'excludes a listed id from an SSN match' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false, exclude_ids_for_name_and_ssn: [target_client.id])

      expect(results.to_a).to eq([])
    end

    it 'does not exclude an SSN match for an id that is not in the list' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false, exclude_ids_for_name_and_ssn: [other_client.id])

      expect(results.to_a).to eq([target_client])
    end

    it 'excludes a listed id from a name match' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('Zzexclude Zztarget', sorted: false, exclude_ids_for_name_and_ssn: [target_client.id])

      expect(results.to_a).to eq([])
    end

    it 'does not exclude a DOB match for the same id' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('05/05/1980', sorted: false, exclude_ids_for_name_and_ssn: [target_client.id])

      expect(results.to_a).to eq([target_client])
    end

    it 'does not exclude anything when the parameter is omitted' do
      results = GrdaWarehouse::Hud::Client.searchable.text_searcher('999-88-7777', sorted: false)

      expect(results.to_a).to eq([target_client])
    end
  end
end
