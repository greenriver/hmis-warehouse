###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::SSNSelector do
  subject(:selected) do
    described_class.call(dest_attr: dest_attr, source_clients: source_clients, use_oldest: use_oldest)
  end

  let(:dest_attr) { {} }
  let(:source_clients) { [] }
  let(:use_oldest) { true }
  let(:hud_util) { instance_double('HudUtil') }
  let(:valid_ssns) do
    [
      '012345678',
      '012456789',
      '012567890',
      '012678901',
      '012789012',
      '012890123',
      '012901234',
      '012912345',
      '012923456',
    ]
  end

  let(:ssn_full_valid) { valid_ssns[0] }
  let(:ssn_partial_numeric) { valid_ssns[1] }
  let(:ssn_quality_two) { valid_ssns[2] }
  let(:ssn_older_full) { valid_ssns[3] }
  let(:ssn_newer_full) { valid_ssns[4] }
  let(:ssn_null_date_first) { valid_ssns[5] }
  let(:ssn_null_date_second) { valid_ssns[6] }
  let(:ssn_newest_with_date) { valid_ssns[7] }
  let(:ssn_extra) { valid_ssns[8] }
  let(:hyphenated_ssn) { '123-45-6789' }

  before do
    allow(hud_util).to receive(:ssn_data_quality_options).
      and_return({ 1 => 'Full', 2 => 'Partial', 8 => 'Other', 9 => 'DK', 99 => 'Missing' })
    allow(hud_util).to receive(:valid_social?) do |ssn|
      ssn.present? && ssn.length == 9 && ssn != '111111111'
    end
    allow(HudHelper).to receive(:util).and_return(hud_util)
  end

  it 'generates valid SSNs for the scenarios' do
    valid_ssns.each do |ssn|
      expect(hud_util.valid_social?(ssn)).to be(true), "expected #{ssn} to be a valid SSN"
    end
  end

  describe '.call' do
    context 'when no source client has an SSN value' do
      it 'returns the destination with blank SSN and unknown quality' do
        expect(selected[:SSN]).to be_nil
        expect(selected[:SSNDataQuality]).to eq(99)
      end
    end

    context 'when a source client has DQ 1 with a valid SSN' do
      let(:source_clients) do
        [
          {
            SSN: ssn_full_valid,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'keeps the full SSN data quality' do
        expect(selected[:SSN]).to eq(ssn_full_valid)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when the source is DQ 1 with an invalid 9-digit SSN' do
      let(:source_clients) do
        [
          {
            SSN: '111111111',
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'demotes the SSN data quality to partial and keeps the value' do
        expect(selected[:SSN]).to eq('111111111')
        expect(selected[:SSNDataQuality]).to eq(2)
      end
    end

    context 'when the source is DQ 1 but has no numeric SSN' do
      let(:source_clients) do
        [
          {
            SSN: 'ABCDEF',
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
        ]
      end

      it 'drops the value and reports unknown data quality' do
        expect(selected[:SSN]).to be_nil
        expect(selected[:SSNDataQuality]).to eq(99)
      end
    end

    context 'when the source has DQ other than 1 or 2' do
      let(:source_clients) do
        [
          {
            SSN: hyphenated_ssn,
            SSNDataQuality: 8,
            DateCreated: Time.zone.local(2022, 6, 1),
            id: 1,
          },
          {
            SSN: ssn_full_valid,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2022, 6, 2),
            id: 2,
          },
        ]
      end

      it 'keeps each SSN value with its original data quality when selected' do
        expect(selected[:SSN]).to eq(ssn_full_valid)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when multiple sources exist with different qualities' do
      let(:source_clients) do
        [
          {
            SSN: ssn_quality_two,
            SSNDataQuality: 2,
            DateCreated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            SSN: ssn_full_valid,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the SSN with the higher quality' do
        expect(selected[:SSN]).to eq(ssn_full_valid)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when sources share quality with mixed-type data quality values' do
      let(:source_clients) do
        [
          {
            SSN: ssn_older_full,
            SSNDataQuality: '1',
            DateCreated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            SSN: ssn_newer_full,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'normalizes tie-breakers and selects the preferred candidate' do
        expect(selected[:SSN]).to eq(ssn_older_full)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when multiple sources have equivalent quality' do
      let(:source_clients) do
        [
          {
            SSN: ssn_older_full,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2021, 1, 1),
            id: 1,
          },
          {
            SSN: ssn_newer_full,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the oldest record when configured to prefer oldest' do
        expect(selected[:SSN]).to eq(ssn_older_full)
        expect(selected[:SSNDataQuality]).to eq(1)
      end

      context 'when configured to use the newest record' do
        let(:use_oldest) { false }

        it 'selects the newest record' do
          expect(selected[:SSN]).to eq(ssn_newer_full)
          expect(selected[:SSNDataQuality]).to eq(1)
        end
      end
    end

    context 'when sources share quality but one record has no DateCreated' do
      let(:source_clients) do
        [
          {
            SSN: ssn_null_date_first,
            SSNDataQuality: 1,
            DateCreated: nil,
            id: 1,
          },
          {
            SSN: ssn_null_date_second,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'prefers the record with a timestamped DateCreated' do
        expect(selected[:SSN]).to eq(ssn_null_date_second)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when preferring newest records but one DateCreated is missing' do
      let(:use_oldest) { false }

      let(:source_clients) do
        [
          {
            SSN: ssn_null_date_first,
            SSNDataQuality: 1,
            DateCreated: nil,
            id: 1,
          },
          {
            SSN: ssn_newest_with_date,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2025, 1, 1),
            id: 2,
          },
        ]
      end

      it 'still prefers the record with a real DateCreated timestamp' do
        expect(selected[:SSN]).to eq(ssn_newest_with_date)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when a source client lacks an id' do
      let(:source_clients) do
        [
          {
            SSN: ssn_full_valid,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2024, 1, 1),
            id: nil,
          },
          {
            SSN: ssn_extra,
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2024, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the candidate with a real id when tie-breakers match' do
        expect(selected[:SSN]).to eq(ssn_extra)
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when a partial SSN demotes data quality' do
      let(:source_clients) do
        [
          {
            SSN: '12345',
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2025, 1, 1),
            id: 1,
          },
          {
            SSN: '123456789',
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2001, 1, 1),
            id: 2,
          },
        ]
      end

      it 'selects the valid complete SSN even if it is older' do
        expect(selected[:SSN]).to eq('123456789')
        expect(selected[:SSNDataQuality]).to eq(1)
      end
    end

    context 'when all candidates are removed due to invalid data' do
      let(:source_clients) do
        [
          {
            SSN: 'ABCDEFGHI',
            SSNDataQuality: 1,
            DateCreated: Time.zone.local(2023, 1, 1),
            id: 1,
          },
          {
            SSN: nil,
            SSNDataQuality: 2,
            DateCreated: Time.zone.local(2022, 1, 1),
            id: 2,
          },
        ]
      end

      it 'returns nil SSN with unknown quality' do
        expect(selected[:SSN]).to be_nil
        expect(selected[:SSNDataQuality]).to eq(99)
      end
    end
  end
end
