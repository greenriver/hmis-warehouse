###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvTwentyTwentySix::Exporter::Client::Overrides, type: :model do
  let(:client) { GrdaWarehouse::Hud::Client.new }
  let(:export) { GrdaWarehouse::HmisExport.new(hash_status: 1) }
  let(:race_fields) { HudHelper.util('2026').race_fields - [:RaceNone] }

  describe '.enforce_required_fields' do
    it 'defaults nil race fields to 0' do
      race_fields.each { |f| client[f] = nil }
      described_class.enforce_required_fields(client)
      race_fields.each do |field|
        expect(client[field]).to eq(0), "expected #{field} to be 0, got #{client[field].inspect}"
      end
    end

    it 'does not overwrite existing values' do
      client[:HispanicLatinaeo] = 1
      client[:White] = 0
      described_class.enforce_required_fields(client)
      expect(client[:HispanicLatinaeo]).to eq(1)
      expect(client[:White]).to eq(0)
    end

    it 'HispanicLatinao (FY2026 name) reflects HispanicLatinaeo (DB column) via alias' do
      # alias_attribute bridges the DB column name to the FY2026 spec name so the CSV
      # export can read the value without a separate rename step.
      expect(client[:HispanicLatinao]).to be nil
      expect(client[:HispanicLatinaeo]).to be nil
      client[:HispanicLatinaeo] = 0
      expect(client[:HispanicLatinao]).to eq(0)
      expect(client[:HispanicLatinaeo]).to eq(0)
      client[:HispanicLatinaeo] = 1
      expect(client[:HispanicLatinao]).to eq(1)
      expect(client[:HispanicLatinaeo]).to eq(1)
      client[:HispanicLatinaeo] = nil
      expect(client[:HispanicLatinao]).to be nil
      expect(client[:HispanicLatinaeo]).to be nil
    end
  end

  describe '.enforce_race_none' do
    it 'sets RaceNone to 99 when all race flags are 0' do
      race_fields.each { |f| client[f] = 0 }
      described_class.enforce_race_none(client)
      expect(client.RaceNone).to eq(99)
    end

    it 'leaves RaceNone nil when at least one race flag is 1' do
      race_fields.each { |f| client[f] = 0 }
      client[:HispanicLatinaeo] = 1
      described_class.enforce_race_none(client)
      expect(client.RaceNone).to be_nil
    end
  end

  describe '.apply_overrides' do
    it 'defaults all-nil race fields to 0 and sets RaceNone to 99' do
      race_fields.each { |f| client[f] = nil }
      described_class.apply_overrides(client, export: export)
      race_fields.each do |field|
        expect(client[field]).to eq(0), "expected #{field} to be 0"
      end
      expect(client.RaceNone).to eq(99)
    end

    it 'preserves a race flag of 1 and does not set RaceNone to 99' do
      race_fields.each { |f| client[f] = 0 }
      client[:HispanicLatinaeo] = 1
      described_class.apply_overrides(client, export: export)
      expect(client[:HispanicLatinaeo]).to eq(1)
      expect(client.RaceNone).to be_nil
    end

    it 'defaults nil HispanicLatinaeo to 0, readable via both column names' do
      # If HispanicLatinaeo is nil, both column names read as 0 after overrides are applied.
      client[:HispanicLatinaeo] = nil
      described_class.apply_overrides(client, export: export)
      expect(client[:HispanicLatinaeo]).to eq(0)
      expect(client[:HispanicLatinao]).to eq(0)
    end
  end
end
