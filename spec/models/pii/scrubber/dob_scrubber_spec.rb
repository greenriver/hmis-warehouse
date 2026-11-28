###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Pii::Scrubber::DobScrubber do
  include ActiveSupport::Testing::TimeHelpers

  let(:client) { create(:grda_warehouse_hud_client, DOB: Date.new(1980, 1, 1)) }

  def pii_attribute(name, type)
    Pii::Scrubber::PiiAttribute.new(name: name, type: type, required: false, level: 1, record: client)
  end

  it 'derives unscrubbed ages from a pre-scrubbed DOB and leaves pre-scrubbed ages alone' do
    dob = pii_attribute(:DOB, :dob)
    age = pii_attribute(:Age, :age)
    pre_aged = pii_attribute(:OtherAge, :age)
    dob.scrub(Date.new(2000, 1, 1))
    pre_aged.scrub(99)

    travel_to(Date.new(2024, 6, 1)) do
      described_class.new.perform([dob, age, pre_aged])
    end

    expect([dob.scrubbed_value, age.scrubbed_value, pre_aged.scrubbed_value]).to eq([Date.new(2000, 1, 1), 24, 99])
  end
end
