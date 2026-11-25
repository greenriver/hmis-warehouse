###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Health::Soap::MassHealth, type: :model do
  before do
    Health::Soap::Config.create!(
      name: 'masshealth',
      user: 'user',
      pass: 'secret',
      sender: 'sender',
      receiver: 'receiver',
      production_url: 'https://masshealth.example.com',
    )
  end

  it 'is configured when the config is fully populated' do
    expect(described_class.new.configured?).to be(true)
  end

  it 'is not configured in sandbox mode' do
    with_sandbox_mode do
      expect(described_class.new.configured?).to be(false)
    end
  end
end
