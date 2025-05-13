# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudUtility2026 do
  let(:json_file_path) { Rails.root.join('lib', 'data', '2026_hud_lists.json') }
  let(:hud_lists) { JSON.parse(File.read(json_file_path)) }

  # These tests for leverage the 2026_hud_lists.json file to dynamically test the
  # utility methods against the actual HUD data definitions.
  #
  # Testing strategy:
  # 1. Load the JSON file containing the HUD data lists/codes
  # 2. For each lookup method in the HUD lists file, test both the forward lookup (code to description)
  #    and reverse lookup (description to code) where applicable
  # 3. Test utility methods that categorize or transform the HUD data
  #
  describe 'translation methods' do
    # Test race_none method instead of race
    describe '#race_none' do
      let(:race_none_list) { hud_lists.find { |list| list['name'] == 'RaceNone' } }

      it 'translates between race_none codes and descriptions' do
        race_none_list['values'].each do |value|
          expect(HudUtility2026.race_none(value['key'])).to eq(value['description'])
          expect(HudUtility2026.race_none(value['description'], true)).to eq(value['key'])
        end
      end
    end

    # Test ethnicity method
    describe '#ethnicity' do
      it 'returns defined ethnicity descriptions' do
        ethnicities = HudUtility2026.ethnicities
        expect(ethnicities).to be_a(Hash)
        expect(ethnicities.keys).to include(:hispanic_latinaeo, :non_hispanic_latinaeo, :unknown)

        # Test forward lookup
        expect(HudUtility2026.ethnicity(:hispanic_latinaeo)).to eq(ethnicities[:hispanic_latinaeo])
        expect(HudUtility2026.ethnicity(:non_hispanic_latinaeo)).to eq(ethnicities[:non_hispanic_latinaeo])
        expect(HudUtility2026.ethnicity(:unknown)).to eq(ethnicities[:unknown])

        # Test reverse lookup
        expect(HudUtility2026.ethnicity(ethnicities[:hispanic_latinaeo], true)).to eq(:hispanic_latinaeo)
        expect(HudUtility2026.ethnicity(ethnicities[:non_hispanic_latinaeo], true)).to eq(:non_hispanic_latinaeo)
        expect(HudUtility2026.ethnicity(ethnicities[:unknown], true)).to eq(:unknown)
      end
    end

    # Test residence_prior_length_of_stay_brief method
    describe '#residence_prior_length_of_stay_brief' do
      it 'translates length of stay codes to brief descriptions' do
        # The method returns brief descriptions, so we need to check the mapping manually
        brief_map = {
          10 => '0-7',
          11 => '0-7',
          2 => '7-30',
          3 => '30-90',
          4 => '90-365',
          5 => '365+',
          8 => '',
          9 => '',
          99 => '',
        }

        brief_map.each do |code, brief|
          expect(HudUtility2026.residence_prior_length_of_stay_brief(code)).to eq(brief)
        end

        # Test reverse lookup for a few values
        expect(HudUtility2026.residence_prior_length_of_stay_brief('0-7', true)).to eq(10)
        expect(HudUtility2026.residence_prior_length_of_stay_brief('7-30', true)).to eq(2)
      end
    end

    # Test project_type method
    describe '#project_type' do
      let(:project_types) { hud_lists.find { |list| list['name'] == 'ProjectType' } }

      it 'translates between project type codes and descriptions' do
        project_types['values'].each do |value|
          expect(HudUtility2026.project_type(value['key'])).to eq(value['description'])
          expect(HudUtility2026.project_type(value['description'], true)).to eq(value['key'])
        end
      end
    end

    # Test project_type_brief method
    describe '#project_type_brief' do
      let(:project_types_brief) { hud_lists.find { |list| list['name'] == 'ProjectTypeBrief' } }

      it 'translates project type codes to brief descriptions' do
        project_types_brief['values'].each do |value|
          expect(HudUtility2026.project_type_brief(value['key'])).to eq(value['description'])
        end
      end
    end

    # Test living_situation method
    describe '#living_situation' do
      # This method uses multiple JSON list sections (current/prior living situations and destinations)
      let(:current_living_situations) { hud_lists.find { |list| list['name'] == 'CurrentLivingSituation' } }
      let(:prior_living_situations) { hud_lists.find { |list| list['name'] == 'PriorLivingSituation' } }
      let(:destinations) { hud_lists.find { |list| list['name'] == 'Destination' } }

      it 'translates all types of living situation codes to descriptions' do
        # Test current living situations
        current_living_situations['values'].each do |value|
          expect(HudUtility2026.living_situation(value['key'])).to eq(value['description'])
        end

        # Test prior living situations
        prior_living_situations['values'].each do |value|
          expect(HudUtility2026.living_situation(value['key'])).to eq(value['description'])
        end

        # Test destinations
        destinations['values'].each do |value|
          expect(HudUtility2026.living_situation(value['key'])).to eq(value['description'])
        end
      end
    end

    # Test time-related brief methods
    describe 'time-related brief methods' do
      describe '#times_homeless_past_three_years_brief' do
        it 'returns brief representations of times homeless counts' do
          expect(HudUtility2026.times_homeless_past_three_years_brief(1)).to eq('1')
          expect(HudUtility2026.times_homeless_past_three_years_brief(2)).to eq('2')
          expect(HudUtility2026.times_homeless_past_three_years_brief(3)).to eq('3')
          expect(HudUtility2026.times_homeless_past_three_years_brief(4)).to eq('4+')
          expect(HudUtility2026.times_homeless_past_three_years_brief(8)).to eq('')
          expect(HudUtility2026.times_homeless_past_three_years_brief(9)).to eq('')
          expect(HudUtility2026.times_homeless_past_three_years_brief(99)).to eq('')

          # Test reverse lookup
          expect(HudUtility2026.times_homeless_past_three_years_brief('1', true)).to eq(1)
          expect(HudUtility2026.times_homeless_past_three_years_brief('4+', true)).to eq(4)
        end
      end

      describe '#months_homeless_past_three_years_brief' do
        it 'returns brief representations of months homeless counts' do
          expect(HudUtility2026.months_homeless_past_three_years_brief(101)).to eq('0-1')
          expect(HudUtility2026.months_homeless_past_three_years_brief(105)).to eq('5')
          expect(HudUtility2026.months_homeless_past_three_years_brief(112)).to eq('12')
          expect(HudUtility2026.months_homeless_past_three_years_brief(113)).to eq('> 12')
          expect(HudUtility2026.months_homeless_past_three_years_brief(8)).to eq('')

          # Test reverse lookup
          expect(HudUtility2026.months_homeless_past_three_years_brief('0-1', true)).to eq(101)
          expect(HudUtility2026.months_homeless_past_three_years_brief('> 12', true)).to eq(113)
        end
      end
    end

    # Test gender method
    describe '#gender' do
      let(:genders) { hud_lists.find { |list| list['name'] == 'Gender' } }

      it 'translates between gender codes and descriptions' do
        genders['values'].each do |value|
          expect(HudUtility2026.gender(value['key'])).to eq(value['description'])
          expect(HudUtility2026.gender(value['description'], true)).to eq(value['key'])
        end
      end
    end

    # Test funding_source method
    describe '#funding_source' do
      let(:funding_sources) { hud_lists.find { |list| list['name'] == 'FundingSource' } }

      it 'translates between funding source codes and descriptions' do
        funding_sources['values'].each do |value|
          expect(HudUtility2026.funding_source(value['key'])).to eq(value['description'])
          expect(HudUtility2026.funding_source(value['description'], true)).to eq(value['key'])
        end
      end
    end

    # Test funding source constants
    describe 'funding source constants' do
      it 'maintains critical funding source reference codes' do
        # These constants are critical for funding-related logic and reporting
        # Breaking changes could affect compliance with HUD requirements
        expect(HudUtility2026.path_funders).to eq([21])
        expect(HudUtility2026.local_or_other_funding_source).to eq(46)
        expect(HudUtility2026.spm_coc_funders).to match_array([2, 3, 4, 5, 43, 44, 54, 55])
      end
    end
  end

  # Test categorization methods
  describe 'categorization methods' do
    describe '#situation_type' do
      it 'categorizes situations correctly based on ID ranges' do
        # Test boundaries and representative values instead of every value
        {
          'Homeless' => [100, 150, 199],
          'Institutional' => [200, 250, 299],
          'Temporary Housing' => [300, 350, 399],
          'Permanent Housing' => [400, 450, 499],
          'Other' => [1, 50, 99],
        }.each do |expected_type, test_ids|
          test_ids.each do |id|
            expect(HudUtility2026.situation_type(id)).to eq(expected_type),
                                                         "Expected ID #{id} to be categorized as #{expected_type}"
          end
        end
      end
    end

    describe '#destination_type' do
      it 'derives destination type from situation type' do
        expect(HudUtility2026.destination_type(101)).to eq('Homeless')
        expect(HudUtility2026.destination_type(204)).to eq('Institutional')
        expect(HudUtility2026.destination_type(302)).to eq('Temporary')
        expect(HudUtility2026.destination_type(410)).to eq('Permanent')
        expect(HudUtility2026.destination_type(8)).to eq('Other')
      end
    end

    describe 'situation grouping methods' do
      it 'correctly groups situations by their appropriate categories' do
        # Instead of checking every situation in the range, verify core functionality:
        # 1. All categorized situations fall within correct ranges
        # 2. All categorized situations are mutually exclusive

        situations = {
          homeless: HudUtility2026.homeless_situations(as: :current),
          institutional: HudUtility2026.institutional_situations(as: :current),
          temporary: HudUtility2026.temporary_situations(as: :current),
          permanent: HudUtility2026.permanent_situations(as: :current),
          other: HudUtility2026.other_situations(as: :current),
        }

        # Check that situations fall in the expected ranges
        expect(situations[:homeless]).to all(be_between(100, 199))
        expect(situations[:institutional]).to all(be_between(200, 299))
        expect(situations[:temporary]).to all(be_between(300, 399))
        expect(situations[:permanent]).to all(be_between(400, 499))
        expect(situations[:other]).to all(be_between(1, 99))

        # Verify situations are mutually exclusive
        all_situations = situations.values.flatten
        expect(all_situations.size).to eq(all_situations.uniq.size)

        # Verify key situations are included
        expect(situations[:homeless]).to include(101, 116, 118) # Emergency shelter, place not meant for habitation, safe haven
        expect(situations[:institutional]).to include(204, 207)  # Psychiatric hospital, jail/prison
        expect(situations[:temporary]).to include(302, 332)      # Transitional housing, Host Home
        expect(situations[:permanent]).to include(410, 421)      # Rental, owned with subsidy
      end
    end
  end

  # Test project type-related methods
  describe 'project type helpers' do
    describe '#project_types_with_inventory' do
      it 'excludes types without inventory' do
        types_without_inventory = [4, 6, 7, 11, 12, 14]
        all_types = HudUtility2026.all_project_types

        expect(HudUtility2026.project_types_with_inventory).to match_array(all_types - types_without_inventory)
      end
    end

    describe '#homeless_project_type_numbers' do
      it 'returns only homeless project types' do
        homeless_types = HudUtility2026.homeless_project_type_numbers

        # Verify that these include emergency shelter, transitional housing, safe haven, street outreach
        expect(homeless_types).to include(0, 1, 2, 4, 8)

        # Verify permanent housing types are not included
        expect(homeless_types).not_to include(3, 9, 10, 13)
      end
    end

    describe '#permanent_housing_project_types' do
      it 'returns only permanent housing project types' do
        ph_types = HudUtility2026.permanent_housing_project_types

        # Should include PSH, PH, and RRH
        expect(ph_types).to match_array([3, 9, 10, 13])
      end
    end
  end

  # Test race/gender field helpers
  describe 'field name helpers' do
    describe '#race_fields' do
      it 'returns all race field names' do
        expect(HudUtility2026.race_fields).to include(:AmIndAKNative, :Asian, :BlackAfAmerican,
                                                      :NativeHIPacific, :White, :RaceNone)
      end
    end

    describe '#gender_fields' do
      it 'returns all gender field names' do
        expect(HudUtility2026.gender_fields).to include(:Woman, :Man, :NonBinary,
                                                        :Transgender, :Questioning, :GenderNone)
      end
    end
  end

  # Test CoC-related methods
  describe 'CoC methods' do
    let(:coc_codes) { hud_lists.find { |list| list['name'] == 'CoCCodes' } }

    describe '#coc_name' do
      it 'returns CoC name for valid code' do
        coc_codes['values'].sample(10).each do |value|
          code = value['key']
          name = value['description']
          # Trim trailing whitespace to handle formatting inconsistency
          expect(HudUtility2026.coc_name(code)).to eq(name.strip)
        end
      end

      it 'returns code itself for invalid code' do
        expect(HudUtility2026.coc_name('INVALID-CODE')).to eq('INVALID-CODE')
      end
    end

    describe '#valid_coc?' do
      it 'returns true for valid CoC codes' do
        coc_codes['values'].sample(10).each do |value|
          expect(HudUtility2026.valid_coc?(value['key'])).to be true
        end
      end

      it 'returns false for invalid CoC codes' do
        expect(HudUtility2026.valid_coc?('INVALID-CODE')).to be false
      end
    end

    describe '#cocs_in_state' do
      it 'filters CoCs by state code' do
        # Test with California
        ca_cocs = HudUtility2026.cocs_in_state('CA')
        expect(ca_cocs.keys.all? { |k| k.start_with?('CA-') }).to be true

        # Test with multiple states
        ca_fl_cocs = HudUtility2026.cocs_in_state(['CA', 'FL'])
        expect(ca_fl_cocs.keys.all? { |k| k.start_with?('CA-') || k.start_with?('FL-') }).to be true
      end

      it 'returns all CoCs when state list is empty' do
        expect(HudUtility2026.cocs_in_state([])).to eq(HudUtility2026.cocs)
      end
    end
  end
end
