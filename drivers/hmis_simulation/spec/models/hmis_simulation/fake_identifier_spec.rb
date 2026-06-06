###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::FakeIdentifier do
  describe '.uuid' do
    it 'starts with FAKE' do
      expect(described_class.uuid).to start_with('FAKE')
    end

    it 'is 32 characters total (matching HUD generate_uuid convention — no dashes)' do
      expect(described_class.uuid.length).to eq(32)
    end

    it 'generates unique values' do
      ids = 20.times.map { described_class.uuid }
      expect(ids.uniq.length).to eq(20)
    end

    it 'has FAKE prefix followed by 28 lowercase hex characters' do
      expect(described_class.uuid).to match(/\AFAKE[0-9a-f]{28}\z/)
    end
  end

  describe '.ssn' do
    it 'starts with 999' do
      expect(described_class.ssn).to start_with('999')
    end

    it 'is 9 digits total' do
      expect(described_class.ssn).to match(/\A999\d{6}\z/)
    end

    it 'generates varied values' do
      ssns = 20.times.map { described_class.ssn }
      expect(ssns.uniq.length).to be > 1
    end
  end

  describe '.first_name' do
    it 'ends with underscore' do
      expect(described_class.first_name).to end_with('_')
    end

    it 'returns a non-empty string before the underscore' do
      name = described_class.first_name
      expect(name.chomp('_')).not_to be_empty
    end

    it 'draws from the city/water-body list' do
      names = 50.times.map { described_class.first_name }
      expect(names.uniq.length).to be > 1
    end
  end

  describe '.last_name' do
    it 'ends with underscore' do
      expect(described_class.last_name).to end_with('_')
    end

    it 'returns a non-empty string before the underscore' do
      name = described_class.last_name
      expect(name.chomp('_')).not_to be_empty
    end

    it 'draws from the Latin plant name list' do
      names = 50.times.map { described_class.last_name }
      expect(names.uniq.length).to be > 1
    end
  end
end
