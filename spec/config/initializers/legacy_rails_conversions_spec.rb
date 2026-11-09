###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Pins how dates and times serialize, given config/initializers/legacy_rails_conversions.rb
# overrides #to_s with a human display format. Code that persists or compares dates as strings
# depends on these behaviors, and gem upgrades have changed them before (Rails 8.1.4 switched
# JSON hash keys from #as_json to #to_s). If a spec here fails after an upgrade, find the code
# that relied on the old behavior before updating the expectation.
# See docs/active-record-arel-and-queries.md
RSpec.describe 'Date and time serialization' do
  let(:date) { Date.new(2025, 1, 29) }
  let(:time) { Time.zone.local(2025, 1, 29, 10, 15, 30) }
  let(:jsonb_type) { ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Jsonb.new }

  describe '#to_s' do
    it 'renders a Date in the human display format' do
      expect(date.to_s).to eq('Jan 29, 2025')
    end

    it 'renders a Time in the human display format, without seconds or zone' do
      expect(time.to_s).to eq('Jan 29, 2025 10:15 am')
    end
  end

  describe 'JSON values' do
    it 'encodes a Date value as ISO 8601' do
      expect({ 'date' => date }.to_json).to eq('{"date":"2025-01-29"}')
    end

    it 'encodes a Time value as ISO 8601' do
      encoded = JSON.parse({ 'time' => time }.to_json)

      expect(Time.zone.parse(encoded['time'])).to eq(time)
    end
  end

  describe 'JSON hash keys' do
    it 'encodes a Date key with #to_s, not ISO 8601' do
      expect({ date => 1 }.to_json).to eq('{"Jan 29, 2025":1}')
    end

    it 'encodes a Time key with #to_s, not ISO 8601' do
      expect({ time => 1 }.to_json).to eq('{"Jan 29, 2025 10:15 am":1}')
    end

    it 'stores a Date key in a jsonb column with #to_s' do
      expect(jsonb_type.serialize({ date => 1 })).to eq('{"Jan 29, 2025":1}')
    end

    it 'stores an explicitly stringified key unchanged' do
      expect(jsonb_type.serialize({ date.iso8601 => 1 })).to eq('{"2025-01-29":1}')
    end
  end
end
