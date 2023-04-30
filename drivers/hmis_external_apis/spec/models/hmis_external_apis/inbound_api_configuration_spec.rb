###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe HmisExternalApis::InboundApiConfiguration, type: :model do
  it 'Creates an api key' do
    create(:inbound_api_configuration)
    expect(HmisExternalApis::InboundApiConfiguration.count).to eq(1)
  end

  it 'Only creates at most two api keys' do
    internal_system = create(:internal_system)
    3.times { create(:inbound_api_configuration, external_system_name: 'E1', internal_system: internal_system) }
    expect(HmisExternalApis::InboundApiConfiguration.count).to eq(2)
    expect(HmisExternalApis::InboundApiConfiguration.pluck(:version).sort).to eq([1, 2])
  end

  it 'checks for a key' do
    created = create(:inbound_api_configuration)
    expect(created.plain_text_api_key_with_fallback).to be_present

    found = HmisExternalApis::InboundApiConfiguration.find_by_api_key(created.plain_text_api_key)

    expect(found).to eq(created)
  end

  it 'returns nil if api key cannot be found' do
    not_found = HmisExternalApis::InboundApiConfiguration.find_by_api_key('badkey')

    expect(not_found).to be_nil
  end
end
