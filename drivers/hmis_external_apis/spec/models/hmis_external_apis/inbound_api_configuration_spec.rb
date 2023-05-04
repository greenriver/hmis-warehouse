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

    validity = HmisExternalApis::InboundApiConfiguration.validate(api_key: created.plain_text_api_key, internal_system: created.internal_system)

    expect(validity).to be true
  end

  it 'returns false if api key cannot be found' do
    validity = HmisExternalApis::InboundApiConfiguration.validate(api_key: 'badkey', internal_system: 'nothing')

    expect(validity).to be false
  end

  it 'returns false if api key internal system does not match' do
    created = create(:inbound_api_configuration)
    validity = HmisExternalApis::InboundApiConfiguration.validate(api_key: created.plain_text_api_key, internal_system: HmisExternalApis::InternalSystem.new)

    expect(validity).to be false
  end
end
