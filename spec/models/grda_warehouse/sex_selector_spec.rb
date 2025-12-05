###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::SexSelector do
  subject(:selected) do
    described_class.call(dest_attr: dest_attr, source_clients: source_clients, prioritization_method: prioritization_method)
  end

  let(:dest_attr) { {} }
  let(:source_clients) { [] }
  let(:prioritization_method) { :newest_first }
  let(:hud_util) { instance_double('HudUtil') }

  before do
    allow(hud_util).to receive(:sexes).and_return(
      {
        0 => 'Female',
        1 => 'Male',
        8 => "Client doesn't know",
        9 => 'Client prefers not to answer',
        99 => 'Data not collected',
      },
    )
    allow(HudHelper).to receive(:util).with('2026').and_return(hud_util)
  end

  describe '.call' do
    context 'when no source client has a Sex value' do
      it 'returns the destination without setting Sex' do
        expect(selected[:Sex]).to be_nil
      end
    end

    context 'when a source client has Sex value 0 (Female)' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'sets Sex to 0' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when a source client has Sex value 1 (Male)' do
      let(:source_clients) do
        [
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'sets Sex to 1' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when a source client has Sex value 8 (Client doesn\'t know)' do
      let(:source_clients) do
        [
          {
            Sex: 8,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'sets Sex to 8' do
        expect(selected[:Sex]).to eq(8)
      end
    end

    context 'when a source client has Sex value 9 (Client prefers not to answer)' do
      let(:source_clients) do
        [
          {
            Sex: 9,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'sets Sex to 9' do
        expect(selected[:Sex]).to eq(9)
      end
    end

    context 'when a source client has Sex value 99 (Data not collected)' do
      let(:source_clients) do
        [
          {
            Sex: 99,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'sets Sex to 99' do
        expect(selected[:Sex]).to eq(99)
      end
    end

    context 'when multiple sources exist with different values' do
      let(:source_clients) do
        [
          {
            Sex: 8,
            DateUpdated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'prefers 0 or 1 over 8, 9, 99' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when sources share preference level with mixed-type values' do
      let(:source_clients) do
        [
          {
            Sex: '1',
            DateUpdated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'normalizes values and selects the most recent preferred value' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when multiple sources have equivalent preference (0 or 1)' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the most recent record when configured to prefer newest' do
        expect(selected[:Sex]).to eq(1)
      end

      context 'when configured with an unsupported prioritization method' do
        let(:prioritization_method) { :oldest_first }

        it 'raises an error for unsupported prioritization method' do
          expect { selected }.to raise_error(ArgumentError, /Invalid prioritization_method: oldest_first/)
        end
      end
    end

    context 'when multiple sources have equivalent preference (8, 9, 99)' do
      let(:source_clients) do
        [
          {
            Sex: 8,
            DateUpdated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            Sex: 9,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the most recent record' do
        expect(selected[:Sex]).to eq(9)
      end
    end

    context 'when sources share preference but one record has no DateUpdated' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: nil,
            id: 1,
          },
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'prefers the record with a timestamped DateUpdated' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when preferring newest records but one DateUpdated is missing' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: nil,
            id: 1,
          },
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2025, 1, 1),
            id: 2,
          },
        ]
      end

      it 'still prefers the record with a real DateUpdated timestamp' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when a source client lacks an id' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2024, 1, 1),
            id: nil,
          },
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2024, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the candidate with a real id when tie-breakers match' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when a preferred value (0 or 1) exists alongside non-preferred values' do
      let(:source_clients) do
        [
          {
            Sex: 8,
            DateUpdated: Time.zone.local(2025, 1, 1),
            id: 1,
          },
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2001, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the preferred value even if it is older' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when all candidates are removed due to invalid data' do
      let(:source_clients) do
        [
          {
            Sex: 999,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
          {
            Sex: nil,
            DateUpdated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'returns nil Sex' do
        expect(selected[:Sex]).to be_nil
      end
    end

    context 'when a candidate has an invalid string value' do
      let(:source_clients) do
        [
          {
            Sex: 'invalid',
            DateUpdated: Time.zone.local(2023, 1, 2),
            id: 1,
          },
        ]
      end

      it 'ignores invalid values and returns nil' do
        expect(selected[:Sex]).to be_nil
      end
    end

    context 'when source clients are ActiveRecord objects' do
      let(:client1) do
        create(:hud_client, Sex: 0, DateUpdated: Time.zone.local(2023, 1, 1))
      end
      let(:client2) do
        create(:hud_client, Sex: 1, DateUpdated: Time.zone.local(2024, 1, 1))
      end
      let(:source_clients) { [client1, client2] }

      it 'normalizes ActiveRecord objects and selects the most recent' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when source clients are plain Hashes' do
      let(:source_clients) do
        [
          {
            'Sex' => 0,
            'DateUpdated' => Time.zone.local(2023, 1, 1),
            'id' => 1,
          },
          {
            'Sex' => 1,
            'DateUpdated' => Time.zone.local(2024, 1, 1),
            'id' => 2,
          },
        ]
      end

      it 'normalizes Hashes and selects the most recent' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when destination already has a Sex value' do
      let(:dest_attr) { { Sex: 1 } }
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'overwrites with the selected value from source clients' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when DateUpdated is a Date object' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Date.new(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'handles Date objects correctly' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when DateUpdated is a DateTime object' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: DateTime.new(2023, 1, 1, 12, 0, 0),
            id: 1,
          },
        ]
      end

      it 'handles DateTime objects correctly' do
        expect(selected[:Sex]).to eq(0)
      end
    end

    context 'when multiple sources have same DateUpdated but different ids' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 2,
          },
          {
            Sex: 1,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'selects the candidate with the lower id' do
        expect(selected[:Sex]).to eq(1)
      end
    end

    context 'when an unsupported source client type is provided' do
      let(:source_clients) { ['invalid'] }

      it 'raises an ArgumentError' do
        expect { selected }.to raise_error(ArgumentError, /Unsupported source client/)
      end
    end

    context 'when DateUpdated has an invalid type' do
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: 'invalid',
            id: 1,
          },
        ]
      end

      it 'raises an ArgumentError' do
        expect { selected }.to raise_error(ArgumentError, /invalid timestamp/)
      end
    end

    context 'when an invalid prioritization_method is provided' do
      let(:prioritization_method) { :invalid_method }
      let(:source_clients) do
        [
          {
            Sex: 0,
            DateUpdated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'raises an ArgumentError' do
        expect { selected }.to raise_error(ArgumentError, /Invalid prioritization_method: invalid_method/)
      end
    end
  end
end
