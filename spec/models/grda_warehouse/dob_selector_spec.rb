###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::DOBSelector do
  subject(:selected) do
    described_class.call(dest_attr: dest_attr, source_clients: source_clients, use_oldest: use_oldest)
  end

  let(:dest_attr) { {} }
  let(:source_clients) { [] }
  let(:use_oldest) { true }
  # object_double, not instance_double: HudHelper.util returns a module.
  let(:hud_util) { object_double(HudUtility2026) }

  # Every case states its reference date explicitly. Validity is judged against
  # DateCreated, never against the suite clock.
  let(:reference) { Time.zone.local(2023, 1, 1) }
  let(:plausible_dob) { Date.new(2003, 1, 1) } # 20 years before reference
  let(:future_dob) { Date.new(2023, 6, 1) } # after reference
  let(:exactly_150_dob) { Date.new(1873, 1, 1) } # exactly 150 years before reference
  let(:too_old_dob) { Date.new(1872, 12, 31) } # 150 years and 1 day before reference

  before do
    allow(hud_util).to receive(:dob_data_quality_options).
      and_return(
        {
          1 => 'Full DOB reported',
          2 => 'Approximate or partial DOB reported',
          8 => "Client doesn't know",
          9 => 'Client prefers not to answer',
          99 => 'Data not collected',
        },
      )
    allow(HudHelper).to receive(:util).and_return(hud_util)
  end

  describe '.call' do
    describe 'validity and demotion' do
      context 'when a DQ 1 DOB precedes DateCreated by a plausible span' do
        let(:source_clients) do
          [{ DOB: plausible_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'keeps the full data quality and the value' do
          expect(selected[:DOB]).to eq(plausible_dob)
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when a DQ 1 DOB falls after DateCreated' do
        let(:source_clients) do
          [{ DOB: future_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'demotes to approximate and keeps the value' do
          expect(selected[:DOB]).to eq(future_dob)
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when a DQ 1 DOB is 150 years and one day before DateCreated' do
        let(:source_clients) do
          [{ DOB: too_old_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'demotes to approximate and keeps the value' do
          expect(selected[:DOB]).to eq(too_old_dob)
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when a DQ 1 DOB is exactly 150 years before DateCreated' do
        let(:source_clients) do
          [{ DOB: exactly_150_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'treats the boundary as valid and keeps the full data quality' do
          expect(selected[:DOB]).to eq(exactly_150_dob)
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when a DQ 2 DOB is invalid' do
        let(:source_clients) do
          [{ DOB: future_dob, DOBDataQuality: 2, DateCreated: reference, id: 1 }]
        end

        it 'neither double-demotes nor promotes' do
          expect(selected[:DOB]).to eq(future_dob)
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      [8, 9, 99].each do |dq|
        context "when a DQ #{dq} DOB is invalid" do
          let(:source_clients) do
            [{ DOB: future_dob, DOBDataQuality: dq, DateCreated: reference, id: 1 }]
          end

          it 'leaves the data quality unchanged' do
            expect(selected[:DOB]).to eq(future_dob)
            expect(selected[:DOBDataQuality]).to eq(dq)
          end
        end
      end

      context 'when the only source has a nil DOB' do
        let(:source_clients) do
          [{ DOB: nil, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'drops the candidate' do
          expect(selected[:DOB]).to be_nil
          expect(selected[:DOBDataQuality]).to eq(99)
        end
      end

      context 'when the only source has a blank DOB' do
        let(:source_clients) do
          [{ DOB: '', DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'drops the candidate' do
          expect(selected[:DOB]).to be_nil
          expect(selected[:DOBDataQuality]).to eq(99)
        end
      end

      [3, '', nil].each do |dq|
        context "when the data quality is #{dq.inspect}, outside the HUD list" do
          let(:source_clients) do
            [{ DOB: plausible_dob, DOBDataQuality: dq, DateCreated: reference, id: 1 }]
          end

          it 'reports data not collected and keeps the value' do
            expect(selected[:DOB]).to eq(plausible_dob)
            expect(selected[:DOBDataQuality]).to eq(99)
          end
        end
      end

      context 'when the data quality arrives as the string 1' do
        let(:source_clients) do
          [{ DOB: future_dob, DOBDataQuality: '1', DateCreated: reference, id: 1 }]
        end

        it 'coerces it and applies the DQ 1 demotion' do
          expect(selected[:DOB]).to eq(future_dob)
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when the DOB arrives as a String' do
        let(:source_clients) do
          [{ DOB: '2003-01-01', DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'accepts it and judges validity the same way' do
          expect(selected[:DOB]).to eq('2003-01-01')
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when a String DOB is invalid' do
        let(:source_clients) do
          [{ DOB: '2023-06-01', DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'demotes it just as it would a Date' do
          expect(selected[:DOB]).to eq('2023-06-01')
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when DateCreated is absent' do
        around { |example| travel_to(Time.zone.local(2023, 1, 1)) { example.run } }

        context 'and the DOB is in the future relative to now' do
          let(:source_clients) do
            [{ DOB: Date.new(2024, 1, 1), DOBDataQuality: 1, DateCreated: nil, id: 1 }]
          end

          it 'falls back to the current time and demotes' do
            expect(selected[:DOB]).to eq(Date.new(2024, 1, 1))
            expect(selected[:DOBDataQuality]).to eq(2)
          end
        end

        context 'and the DOB is plausible relative to now' do
          let(:source_clients) do
            [{ DOB: plausible_dob, DOBDataQuality: 1, DateCreated: nil, id: 1 }]
          end

          it 'keeps the full data quality' do
            expect(selected[:DOB]).to eq(plausible_dob)
            expect(selected[:DOBDataQuality]).to eq(1)
          end
        end
      end
    end

    describe 'selection and tie-breaking' do
      context 'when no source client has a DOB' do
        it 'returns a blank DOB with unknown quality' do
          expect(selected[:DOB]).to be_nil
          expect(selected[:DOBDataQuality]).to eq(99)
        end
      end

      context 'when an older DQ 1 record has an impossible DOB (the QA scenario)' do
        let(:source_clients) do
          [
            { DOB: Date.new(2022, 6, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            { DOB: Date.new(2002, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'prefers the newer record whose DOB is possible' do
          expect(selected[:DOB]).to eq(Date.new(2002, 1, 1))
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when a valid DQ 1 competes with a valid DQ 2' do
        let(:source_clients) do
          [
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 2, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            { DOB: plausible_dob, DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'prefers the higher quality regardless of dates' do
          expect(selected[:DOB]).to eq(plausible_dob)
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when a demoted invalid DOB is older than a genuinely approximate one' do
        let(:source_clients) do
          [
            # DQ 1 but impossible, so demoted to 2. Older DateCreated.
            { DOB: Date.new(2022, 6, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            # Genuinely approximate and possible. Newer DateCreated.
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 2, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'ranks validity ahead of age at equal data quality' do
          expect(selected[:DOB]).to eq(Date.new(1990, 1, 1))
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when two valid DQ 1 records differ only by DateCreated' do
        let(:source_clients) do
          [
            { DOB: Date.new(1980, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'selects the oldest record' do
          expect(selected[:DOB]).to eq(Date.new(1980, 1, 1))
        end

        context 'when configured to prefer the newest' do
          let(:use_oldest) { false }

          it 'selects the newest record' do
            expect(selected[:DOB]).to eq(Date.new(1990, 1, 1))
          end
        end
      end

      context 'when one of two equal records has no DateCreated' do
        let(:source_clients) do
          [
            { DOB: Date.new(1980, 1, 1), DOBDataQuality: 1, DateCreated: nil, id: 1 },
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'prefers the timestamped record' do
          expect(selected[:DOB]).to eq(Date.new(1990, 1, 1))
        end

        context 'when configured to prefer the newest' do
          let(:use_oldest) { false }

          it 'still prefers the timestamped record' do
            expect(selected[:DOB]).to eq(Date.new(1990, 1, 1))
          end
        end
      end

      context 'when quality, validity, and DateCreated all tie' do
        let(:source_clients) do
          [
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 7 },
            { DOB: Date.new(1980, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 3 },
          ]
        end

        it 'selects the lowest id' do
          expect(selected[:DOB]).to eq(Date.new(1980, 1, 1))
        end
      end

      context 'when an otherwise tied record has no id' do
        let(:source_clients) do
          [
            { DOB: Date.new(1990, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: nil },
            { DOB: Date.new(1980, 1, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 3 },
          ]
        end

        it 'prefers the record with a real id' do
          expect(selected[:DOB]).to eq(Date.new(1980, 1, 1))
        end
      end

      context 'when every candidate starts at DQ 1 with an impossible DOB' do
        let(:source_clients) do
          [
            { DOB: Date.new(2022, 6, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            { DOB: Date.new(2023, 6, 1), DOBDataQuality: 1, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'still selects the best of them, demoted, with the value kept' do
          expect(selected[:DOB]).to eq(Date.new(2022, 6, 1))
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when every candidate starts at DQ 99 with an impossible DOB' do
        let(:source_clients) do
          [
            { DOB: Date.new(2022, 6, 1), DOBDataQuality: 99, DateCreated: Time.zone.local(2021, 1, 1), id: 1 },
            { DOB: Date.new(2023, 6, 1), DOBDataQuality: 99, DateCreated: Time.zone.local(2022, 1, 1), id: 2 },
          ]
        end

        it 'selects the best of them with nothing to demote' do
          expect(selected[:DOB]).to eq(Date.new(2022, 6, 1))
          expect(selected[:DOBDataQuality]).to eq(99)
        end
      end

      context 'when no source has a DOB but the destination already had one' do
        let(:dest_attr) { { DOB: Date.new(1975, 5, 5), DOBDataQuality: 1 } }
        let(:source_clients) do
          [{ DOB: nil, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'clears the destination DOB and reports data not collected' do
          expect(selected[:DOB]).to be_nil
          expect(selected[:DOBDataQuality]).to eq(99)
        end
      end
    end

    describe 'source normalization' do
      context 'when a source client is an unsupported class' do
        let(:source_clients) { ['not a client'] }

        it 'raises ArgumentError' do
          expect { selected }.to raise_error(ArgumentError, /Unsupported source client/)
        end
      end

      context 'when a source client is an ActiveRecord client, as in production' do
        let(:source_clients) do
          [
            GrdaWarehouse::Hud::Client.new(
              DOB: Date.new(2022, 6, 1),
              DOBDataQuality: 1,
              DateCreated: Time.zone.local(2021, 1, 1),
            ),
            GrdaWarehouse::Hud::Client.new(
              DOB: Date.new(2002, 1, 1),
              DOBDataQuality: 1,
              DateCreated: Time.zone.local(2022, 1, 1),
            ),
          ]
        end

        it 'reads the HUD attributes off the record and demotes the impossible DOB' do
          expect(selected[:DOB]).to eq(Date.new(2002, 1, 1))
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end

      context 'when DateCreated is a Date rather than a Time' do
        let(:source_clients) do
          [{ DOB: Date.new(2022, 6, 1), DOBDataQuality: 1, DateCreated: Date.new(2021, 1, 1), id: 1 }]
        end

        it 'accepts it as the reference date' do
          expect(selected[:DOB]).to eq(Date.new(2022, 6, 1))
          expect(selected[:DOBDataQuality]).to eq(2)
        end
      end

      context 'when DateCreated is a type that cannot be a timestamp' do
        let(:source_clients) do
          [{ DOB: plausible_dob, DOBDataQuality: 1, DateCreated: 'not a date', id: 1 }]
        end

        it 'raises ArgumentError rather than guessing' do
          expect { selected }.to raise_error(ArgumentError, /invalid timestamp/)
        end
      end

      context 'when the destination carries attributes this selector does not own' do
        let(:dest_attr) { { FirstName: 'Blair', SSN: '555555555', DOB: nil, DOBDataQuality: nil } }
        let(:source_clients) do
          [{ DOB: plausible_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }]
        end

        it 'returns them untouched alongside the chosen DOB' do
          expect(selected[:FirstName]).to eq('Blair')
          expect(selected[:SSN]).to eq('555555555')
          expect(selected[:DOB]).to eq(plausible_dob)
        end
      end

      context 'when a source client is a HashWithIndifferentAccess' do
        let(:source_clients) do
          [{ DOB: plausible_dob, DOBDataQuality: 1, DateCreated: reference, id: 1 }.with_indifferent_access]
        end

        it 'is accepted' do
          expect(selected[:DOB]).to eq(plausible_dob)
          expect(selected[:DOBDataQuality]).to eq(1)
        end
      end
    end
  end
end
