###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Talentlms::Config, type: :model do
  let(:config) { described_class.new(subdomain: 'sandbox-test', api_key: '1234') }

  before do
    stub_request(:any, /talentlms/).to_return(body: [].to_json)
  end

  it 'reaches TalentLMS outside sandbox mode' do
    expect(config.get('users')).to eq([])
    expect(WebMock).to have_requested(:get, /talentlms/).once
  end

  it 'refuses #get in sandbox mode without a request' do
    with_sandbox_mode do
      expect { config.get('users') }.to raise_error(SandboxMode::IntegrationDisabled, 'TalentLMS is disabled in sandbox mode')
    end
    expect(WebMock).not_to have_requested(:any, /talentlms/)
  end

  it 'refuses #post in sandbox mode without a request' do
    with_sandbox_mode do
      expect { config.post('usersignup', { login: 'x' }) }.to raise_error(SandboxMode::IntegrationDisabled, 'TalentLMS is disabled in sandbox mode')
    end
    expect(WebMock).not_to have_requested(:any, /talentlms/)
  end
end
