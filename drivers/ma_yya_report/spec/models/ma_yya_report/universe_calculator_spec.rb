###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MaYyaReport::UniverseCalculator do
  let(:user) { create(:user) }
  let(:filter) do
    ::Filters::FilterBase.new(
      user_id: user.id,
      start: Date.new(2024, 1, 1),
      end: Date.new(2024, 12, 31),
      enforce_one_year_range: false,
    )
  end
  let(:calculator) { described_class.new(filter) }

  describe '#initialize' do
    it 'sets the filter' do
      expect(calculator.filter).to eq(filter)
    end
  end

  describe 'private helper methods' do
    describe '#homeless_cls?' do
      it 'identifies homeless current living situations' do
        homeless_codes = [116, 101, 118, 302, 336, 335]
        non_homeless_codes = [410, 435, 421, 411, 422, 423]

        aggregate_failures 'homeless CLS identification' do
          homeless_codes.each do |code|
            cls = OpenStruct.new(CurrentLivingSituation: code)
            expect(calculator.send(:homeless_cls?, cls)).to be true
          end

          non_homeless_codes.each do |code|
            cls = OpenStruct.new(CurrentLivingSituation: code)
            expect(calculator.send(:homeless_cls?, cls)).to be false
          end
        end
      end
    end

    describe '#enrollment_overlaps_range?' do
      let(:start_date) { filter.start }
      let(:end_date) { filter.end }

      it 'determines enrollment overlap correctly' do
        aggregate_failures 'enrollment overlap scenarios' do
          # Starts before and ends after range
          enrollment = OpenStruct.new(
            entry_date: start_date - 1.day,
            exit_date: end_date + 1.day,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be true

          # Starts during range
          enrollment = OpenStruct.new(
            entry_date: start_date + 1.day,
            exit_date: end_date + 1.day,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be true

          # Ends during range
          enrollment = OpenStruct.new(
            entry_date: start_date - 1.day,
            exit_date: end_date - 1.day,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be true

          # Ongoing enrollment (no end date)
          enrollment = OpenStruct.new(
            entry_date: start_date - 1.day,
            exit_date: nil,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be true

          # Ends before range
          enrollment = OpenStruct.new(
            entry_date: start_date - 10.days,
            exit_date: start_date - 1.day,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be false

          # Starts after range
          enrollment = OpenStruct.new(
            entry_date: end_date + 1.day,
            exit_date: end_date + 10.days,
          )
          expect(calculator.send(:enrollment_overlaps_range?, enrollment)).to be false
        end
      end
    end

    describe '#enrollment_started_during_range?' do
      let(:start_date) { filter.start }
      let(:end_date) { filter.end }

      it 'determines enrollment start timing correctly' do
        aggregate_failures 'enrollment start timing scenarios' do
          # Starting on start date
          enrollment = OpenStruct.new(entry_date: start_date)
          expect(calculator.send(:enrollment_started_during_range?, enrollment)).to be true

          # Starting during range
          enrollment = OpenStruct.new(entry_date: start_date + 6.months)
          expect(calculator.send(:enrollment_started_during_range?, enrollment)).to be true

          # Starting on end date
          enrollment = OpenStruct.new(entry_date: end_date)
          expect(calculator.send(:enrollment_started_during_range?, enrollment)).to be true

          # Starting before range
          enrollment = OpenStruct.new(entry_date: start_date - 1.day)
          expect(calculator.send(:enrollment_started_during_range?, enrollment)).to be false

          # Starting after range
          enrollment = OpenStruct.new(entry_date: end_date + 1.day)
          expect(calculator.send(:enrollment_started_during_range?, enrollment)).to be false
        end
      end
    end

    describe '#homeless_enrollment?' do
      it 'identifies homeless project types correctly' do
        aggregate_failures 'homeless project type identification' do
          # Homeless project types
          HudHelper.util.homeless_project_types.each do |project_type|
            enrollment = OpenStruct.new(project_type: project_type)
            expect(calculator.send(:homeless_enrollment?, enrollment)).to be true
          end

          # Non-homeless project types
          non_homeless_types = [3, 6, 9, 10, 12, 13] # Common non-homeless project types
          non_homeless_types.each do |project_type|
            enrollment = OpenStruct.new(project_type: project_type)
            expect(calculator.send(:homeless_enrollment?, enrollment)).to be false
          end
        end
      end
    end

    describe '#gender' do
      it 'processes gender values correctly' do
        aggregate_failures 'gender processing' do
          # Woman only
          client = OpenStruct.new(gender_multi: [0], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(0)

          # Man only
          client = OpenStruct.new(gender_multi: [1], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(1)

          # Transgender (priority over non-binary)
          client = OpenStruct.new(gender_multi: [4, 5], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(5)

          # Non-binary
          client = OpenStruct.new(gender_multi: [4], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(4)

          # Questioning
          client = OpenStruct.new(gender_multi: [6], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(6)

          # Doesn't know
          client = OpenStruct.new(gender_multi: [8], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(6)

          # Prefers not to answer
          client = OpenStruct.new(gender_multi: [9], GenderNone: nil)
          expect(calculator.send(:gender, client)).to eq(6)

          # Other cases use GenderNone
          client = OpenStruct.new(gender_multi: [2], GenderNone: 99)
          expect(calculator.send(:gender, client)).to eq(99)
        end
      end
    end

    describe '#race' do
      it 'processes race values correctly' do
        aggregate_failures 'race processing' do
          # Race none codes
          [8, 9, 99].each do |race_none|
            client = OpenStruct.new(RaceNone: race_none, race_fields: [])
            expect(calculator.send(:race, client)).to eq(race_none)
          end

          # HispanicLatinaeo
          client = OpenStruct.new(RaceNone: nil, race_fields: ['HispanicLatinaeo'])
          expect(calculator.send(:race, client)).to eq(6)

          # No race fields
          client = OpenStruct.new(RaceNone: nil, race_fields: [])
          expect(calculator.send(:race, client)).to eq(99)

          # Multi-racial (excluding HispanicLatinaeo) - should return 6 for HispanicLatinaeo first
          client = OpenStruct.new(RaceNone: nil, race_fields: ['AmIndAKNative', 'Asian', 'HispanicLatinaeo'])
          expect(calculator.send(:race, client)).to eq(6) # HispanicLatinaeo takes priority

          # Multi-racial (truly multi-racial without HispanicLatinaeo)
          client = OpenStruct.new(RaceNone: nil, race_fields: ['AmIndAKNative', 'Asian'])
          expect(calculator.send(:race, client)).to eq(10)
        end
      end

      it 'returns specific race code for single race' do
        client = OpenStruct.new(RaceNone: nil, race_fields: ['AmIndAKNative'])
        expect(calculator.send(:race, client)).to eq(1)

        client = OpenStruct.new(RaceNone: nil, race_fields: ['Asian'])
        expect(calculator.send(:race, client)).to eq(2)

        client = OpenStruct.new(RaceNone: nil, race_fields: ['White'])
        expect(calculator.send(:race, client)).to eq(5)
      end
    end

    describe '#ethnicity' do
      it 'returns HispanicLatinaeo value' do
        client = OpenStruct.new(HispanicLatinaeo: 1)
        expect(calculator.send(:ethnicity, client)).to eq(1)
      end
    end

    describe '#currently_homeless?' do
      it 'determines homelessness status correctly' do
        aggregate_failures 'homelessness determination' do
          # Homeless enrollment type (ES = 1)
          homeless_enrollment = OpenStruct.new(project_type: 1)
          expect(calculator.send(:currently_homeless?, [homeless_enrollment])).to be true

          # Homeless CLS at entry
          entry_date = Date.new(2024, 6, 1)
          enrollment_record = OpenStruct.new(
            current_living_situations: [
              OpenStruct.new(
                InformationDate: entry_date,
                CurrentLivingSituation: 116, # Place not meant for habitation
              ),
            ],
          )
          enrollment = OpenStruct.new(
            project_type: 3, # PSH (not homeless project type)
            entry_date: entry_date,
            enrollment: enrollment_record,
          )
          expect(calculator.send(:currently_homeless?, [enrollment])).to be true

          # Not homeless (non-homeless project type with non-homeless CLS)
          enrollment_record = OpenStruct.new(
            current_living_situations: [
              OpenStruct.new(
                InformationDate: entry_date,
                CurrentLivingSituation: 410, # Rental by client
              ),
            ],
          )
          enrollment = OpenStruct.new(
            project_type: 3, # PSH (not homeless project type)
            entry_date: entry_date,
            enrollment: enrollment_record,
          )
          expect(calculator.send(:currently_homeless?, [enrollment])).to be false
        end
      end
    end

    describe '#at_risk_of_homelessness?' do
      it 'determines at-risk status correctly' do
        aggregate_failures 'at-risk determination' do
          # Currently homeless - not at risk
          homeless_enrollment = OpenStruct.new(project_type: 1) # ES (homeless project type)
          expect(calculator.send(:at_risk_of_homelessness?, [homeless_enrollment])).to be false

          # Not homeless but has non-homeless CLS at entry - at risk
          entry_date = Date.new(2024, 6, 1)
          enrollment_record = OpenStruct.new(
            current_living_situations: [
              OpenStruct.new(
                InformationDate: entry_date,
                CurrentLivingSituation: 410, # Rental by client (non-homeless)
              ),
            ],
          )
          enrollment = OpenStruct.new(
            project_type: 3, # PSH (not homeless project type)
            entry_date: entry_date,
            enrollment: enrollment_record,
          )
          expect(calculator.send(:at_risk_of_homelessness?, [enrollment])).to be true

          # No CLS at entry - not at risk (test with different entry date so cls_at_entry returns nil)
          different_entry_date = Date.new(2024, 7, 1)
          enrollment_record = OpenStruct.new(
            current_living_situations: [
              OpenStruct.new(
                InformationDate: entry_date, # Different from enrollment entry date
                CurrentLivingSituation: 410,
              ),
            ],
          )
          enrollment = OpenStruct.new(
            project_type: 3, # PSH (not homeless project type)
            entry_date: different_entry_date, # Different date, so cls_at_entry returns nil
            enrollment: enrollment_record,
          )

          expect(calculator.send(:at_risk_of_homelessness?, [enrollment])).to be false
        end
      end
    end

    describe '#enrolled_in_street_outreach?' do
      it 'identifies street outreach enrollment correctly' do
        aggregate_failures 'street outreach identification' do
          # Street outreach project (type 4)
          project = OpenStruct.new(project_type: 4)
          enrollment_record = OpenStruct.new(project: project, ReferralSource: nil)
          so_enrollment = OpenStruct.new(enrollment: enrollment_record)
          expect(calculator.send(:enrolled_in_street_outreach?, [so_enrollment])).to be true

          # Referral from outreach project (source 7)
          project = OpenStruct.new(project_type: 1) # Not SO
          enrollment_record = OpenStruct.new(project: project, ReferralSource: 7)
          enrollment = OpenStruct.new(enrollment: enrollment_record)
          expect(calculator.send(:enrolled_in_street_outreach?, [enrollment])).to be true

          # Non-SO project without outreach referral
          project = OpenStruct.new(project_type: 1)
          enrollment_record = OpenStruct.new(project: project, ReferralSource: 1)
          enrollment = OpenStruct.new(enrollment: enrollment_record)
          expect(calculator.send(:enrolled_in_street_outreach?, [enrollment])).to be false
        end
      end
    end

    describe '#initial_contact?' do
      let(:start_date) { filter.start }

      it 'determines initial contact correctly' do
        aggregate_failures 'initial contact determination' do
          # Entry during range with no prior entries within 24 months
          enrollment1 = OpenStruct.new(entry_date: start_date + 1.month)
          enrollment2 = OpenStruct.new(entry_date: start_date - 25.months) # Outside lookback
          expect(calculator.send(:initial_contact?, [enrollment1, enrollment2])).to be true

          # Entry during range with prior entry within 24 months
          enrollment1 = OpenStruct.new(entry_date: start_date + 1.month)
          enrollment2 = OpenStruct.new(entry_date: start_date - 6.months) # Within lookback
          expect(calculator.send(:initial_contact?, [enrollment1, enrollment2])).to be false

          # No entry during range
          enrollment = OpenStruct.new(entry_date: start_date - 1.day)
          expect(calculator.send(:initial_contact?, [enrollment])).to be false
        end
      end
    end

    describe '#language' do
      it 'determines language correctly' do
        aggregate_failures 'language determination' do
          # English when translation_needed is 0
          enrollment = OpenStruct.new(translation_needed: 0, preferred_language: nil)
          expect(calculator.send(:language, enrollment)).to eq('English')

          # Spanish when preferred_language is 367
          enrollment = OpenStruct.new(translation_needed: 1, preferred_language: 367)
          expect(calculator.send(:language, enrollment)).to eq('Spanish')

          # Other when preferred_language is present but not Spanish
          enrollment = OpenStruct.new(translation_needed: 1, preferred_language: 100)
          expect(calculator.send(:language, enrollment)).to eq('Other')

          # nil when no language information available
          enrollment = OpenStruct.new(translation_needed: nil, preferred_language: nil)
          expect(calculator.send(:language, enrollment)).to be_nil
        end
      end
    end
  end
end
