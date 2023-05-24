###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

RSpec.describe HmisExternalApis::ExternalId, type: :model do
  let(:ds1) { create :hmis_data_source }
  let(:client) { create :hmis_hud_client, data_source: ds1 }
  let(:external_id) { create :mci_external_id, source: client, value: '87654321' }

  it 'injects has_many' do
    expect(client.external_ids).to contain_exactly(external_id)
  end

  describe 'injected search' do
    it 'includes client with matching external ID' do
      results = Hmis::Hud::Client.matching_search_term(external_id.value)
      expect(results).to contain_exactly(client)
    end

    it 'includes client with matching external ID (alphanumeric)' do
      external_id.update(value: 'abcdefg1234567')
      results = Hmis::Hud::Client.matching_search_term(external_id.value)
      expect(results).to contain_exactly(client)
    end

    it 'does not include client if ID is not an exact match' do
      results = Hmis::Hud::Client.matching_search_term("#{external_id.value}foo")
      expect(results).to be_empty
    end
  end
end
