# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Race and Ethnicity Counts', type: :model do
  include_context 'HUD pit context'

  let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
  let(:es_project) { create_project(project_type: 0) } # ES-EE
  let(:adult_dob) { pit_date - 30.years }
  let(:child_dob) { pit_date - 5.years }
  let(:all_primary_race_keys) { [:AmIndAKNative, :Asian, :BlackAfAmerican, :NativeHIPacific, :White, :MidEastNAfrican] }

  # Helper to create a client with specific race/ethnicity flags and enroll them
  def create_and_enroll_client_for_race_test(uid:, household_id:, race_attrs:, is_hoh: true, rel_to_hoh: nil)
    client = create_client_with_warehouse_link(uid: uid, dob: is_hoh ? adult_dob : child_dob)
    client.update!(race_attrs)
    create_enrollment(
      client: client,
      project: es_project,
      entry_date: pit_date,
      relationship_to_ho_h: rel_to_hoh || (is_hoh ? 1 : 3),
      household_id: household_id,
    )
    client
  end

  # Helper to build the full race_attrs hash for a client being tested
  def build_race_attributes(target_race_keys, is_hispanic, all_keys)
    attrs = { HispanicLatinaeo: (is_hispanic ? 1 : 0) }
    # Ensure all primary race keys are initialized, defaulting to 0
    all_keys.each { |key| attrs[key] = 0 }
    # Set target race(s) to 1
    Array(target_race_keys).each { |key| attrs[key] = 1 }
    attrs
  end

  # Shared examples for testing a single primary race category
  RSpec.shared_examples 'a single race category test' do |race_key, race_name, cell_non_hisp_only, cell_hisp_only|
    let(:multi_racial_non_hisp_cell) { 'B25' } # Corresponds to :multi_racial
    let(:multi_racial_hisp_cell) { 'B24' }     # Corresponds to :multi_racial_latino
    let(:hoh_race_attrs) { { second_race_for_multi => 1, HispanicLatinaeo: 0 } } # Standard non-interfering HoH

    # Determine a second race for multi-racial tests, ensuring it's different from the primary race_key
    let(:second_race_for_multi) do
      sr = :White # Default second race
      sr = :Asian if race_key == :White # If primary is White, use Asian as second
      sr
    end

    # --- Non-Hispanic/Latina/e/o Tests ---
    describe "#{race_name} (only)" do # This will effectively test the non-Hispanic "only" scenario
      context "when a client is #{race_name} only (not Hispanic/Latino)" do
        before do
          household_id = "race_#{race_key.to_s.downcase}_only_non_hisp"
          create_and_enroll_client_for_race_test(
            uid: "hoh_for_#{household_id}", household_id: household_id, race_attrs: hoh_race_attrs, is_hoh: true,
          )
          test_client_attrs = build_race_attributes([race_key], false, all_primary_race_keys)
          create_and_enroll_client_for_race_test(
            uid: "client_for_#{household_id}", household_id: household_id, race_attrs: test_client_attrs, is_hoh: false,
          )
        end

        it "counts the client in #{race_name} (only, not Hispanic/Latina/e/o)" do
          report = run_report(questions: [question])
          count = report.answer(question: question, cell: cell_non_hisp_only)
          expect(count.value).to eq(1)
        end
      end

      context "when a client is #{race_name} and another race (not Hispanic/Latino)" do
        before do
          household_id = "race_#{race_key.to_s.downcase}_multi_non_hisp"
          create_and_enroll_client_for_race_test(
            uid: "hoh_for_#{household_id}", household_id: household_id, race_attrs: hoh_race_attrs, is_hoh: true,
          )
          test_client_attrs = build_race_attributes([race_key, second_race_for_multi], false, all_primary_race_keys)
          create_and_enroll_client_for_race_test(
            uid: "client_for_#{household_id}", household_id: household_id, race_attrs: test_client_attrs, is_hoh: false,
          )
        end

        it "counts in Multi-Racial (not Hispanic/Latina/e/o) and not in #{race_name} (only)" do
          report = run_report(questions: [question])
          only_count = report.answer(question: question, cell: cell_non_hisp_only)
          expect(only_count.value).to eq(0)

          multi_count = report.answer(question: question, cell: multi_racial_non_hisp_cell)
          expect(multi_count.value).to eq(1)
        end
      end
    end

    # --- Hispanic/Latina/e/o Tests ---
    describe "#{race_name} & Hispanic/Latina/e/o" do
      context "when a client is #{race_name} only and Hispanic/Latino" do
        before do
          household_id = "race_#{race_key.to_s.downcase}_only_hisp"
          create_and_enroll_client_for_race_test(
            uid: "hoh_for_#{household_id}", household_id: household_id, race_attrs: hoh_race_attrs, is_hoh: true,
          )
          test_client_attrs = build_race_attributes([race_key], true, all_primary_race_keys)
          create_and_enroll_client_for_race_test(
            uid: "client_for_#{household_id}", household_id: household_id, race_attrs: test_client_attrs, is_hoh: false,
          )
        end

        it "counts the client in #{race_name} & Hispanic/Latina/e/o" do
          report = run_report(questions: [question])
          count = report.answer(question: question, cell: cell_hisp_only)
          expect(count.value).to eq(1)
        end
      end

      context "when a client is #{race_name}, another race, and Hispanic/Latino" do
        before do
          household_id = "race_#{race_key.to_s.downcase}_multi_hisp"
          create_and_enroll_client_for_race_test(
            uid: "hoh_for_#{household_id}", household_id: household_id, race_attrs: hoh_race_attrs, is_hoh: true,
          )
          test_client_attrs = build_race_attributes([race_key, second_race_for_multi], true, all_primary_race_keys)
          create_and_enroll_client_for_race_test(
            uid: "client_for_#{household_id}", household_id: household_id, race_attrs: test_client_attrs, is_hoh: false,
          )
        end

        it "counts in Multi-Racial & Hispanic/Latina/e/o and not in #{race_name} & Hispanic/Latina/e/o" do
          report = run_report(questions: [question])
          only_hisp_count = report.answer(question: question, cell: cell_hisp_only)
          expect(only_hisp_count.value).to eq(0)

          multi_hisp_count = report.answer(question: question, cell: multi_racial_hisp_cell)
          expect(multi_hisp_count.value).to eq(1)
        end
      end
    end
  end

  # --- Applying Shared Examples for each primary race ---
  # Cell mapping from AdultAndChild.rb:
  # B11: native_ak (AmIndAKNative only, not H/L)
  # B12: native_ak_latino (AmIndAKNative only, and H/L)
  # B13: asian (Asian only, not H/L)
  # B14: asian_latino (Asian only, and H/L)
  # B15: black_af_american (Black only, not H/L)
  # B16: black_af_american_latino (Black only, and H/L)
  # B18: mid_east_na (MENA only, not H/L)
  # B19: mid_east_na_latino (MENA only, and H/L)
  # B20: native_pi (Native PI only, not H/L)
  # B21: native_pi_latino (Native PI only, and H/L)
  # B22: white (White only, not H/L)
  # B23: white_latino (White only, and H/L)

  it_behaves_like 'a single race category test', :AmIndAKNative, 'American Indian, Alaska Native, or Indigenous', 'B11', 'B12'
  it_behaves_like 'a single race category test', :Asian, 'Asian or Asian American', 'B13', 'B14'
  it_behaves_like 'a single race category test', :BlackAfAmerican, 'Black, African American, or African', 'B15', 'B16'
  it_behaves_like 'a single race category test', :MidEastNAfrican, 'Middle Eastern or North African', 'B18', 'B19'
  it_behaves_like 'a single race category test', :NativeHIPacific, 'Native Hawaiian or Pacific Islander', 'B20', 'B21'
  it_behaves_like 'a single race category test', :White, 'White', 'B22', 'B23'

  # --- Retaining Specific Tests for Hispanic (only) and Multi-Racial Categories ---

  describe 'Hispanic/Latina/e/o (only)' do
    context 'when a client is Hispanic/Latino only (no other race selected)' do
      before do
        household_id = 'race_latino_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_latino_only',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 }, # Non-Hispanic HoH
          is_hoh: true,
        )
        # Client is Hispanic/Latino, and all primary race fields are 0
        test_client_attrs = build_race_attributes([], true, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_latino_only_client',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :latino_only is cell B17 for AdultAndChild question
        count = report.answer(question: question, cell: 'B17')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Hispanic/Latino AND another race (e.g., White)' do
      before do
        household_id = 'race_latino_plus_white_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_latino_plus_white',
          household_id: household_id,
          race_attrs: { AmIndAKNative: 1, HispanicLatinaeo: 0 },
          is_hoh: true,
        )
        test_client_attrs = build_race_attributes([:White], true, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_latino_white_client',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'does NOT count in Hispanic/Latina/e/o (only), but in White & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        latino_only_count = report.answer(question: question, cell: 'B17')
        expect(latino_only_count.value).to eq(0)

        # :white_latino is cell B23 for AdultAndChild question
        white_latino_count = report.answer(question: question, cell: 'B23')
        expect(white_latino_count.value).to eq(1)
      end
    end
  end

  describe 'Multi-Racial & Hispanic/Latina/e/o' do
    context 'when a client identifies with two races (e.g., AmIndAKNative and Asian) AND is Hispanic/Latino' do
      before do
        household_id = 'race_multi_latino_explicit_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_multi_latino_explicit',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true,
        )
        test_client_attrs = build_race_attributes([:AmIndAKNative, :Asian], true, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_latino_client_explicit',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'counts the client in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        # :multi_racial_latino is cell B24
        count = report.answer(question: question, cell: 'B24')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client identifies with three races AND is Hispanic/Latino' do
      before do
        household_id = 'race_multi_latino_explicit_2'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_multi_latino_explicit_2',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true,
        )
        test_client_attrs = build_race_attributes([:AmIndAKNative, :Asian, :BlackAfAmerican], true, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_latino_client_explicit_2',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'counts the client in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B24')
        expect(count.value).to eq(1)
      end
    end
  end

  describe 'Multi-Racial (all other)' do
    context 'when a client identifies with two races (e.g., Black and White) AND is NOT Hispanic/Latino' do
      before do
        household_id = 'race_multi_non_hispanic_explicit_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_multi_non_hispanic_explicit',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 },
          is_hoh: true,
        )
        test_client_attrs = build_race_attributes([:BlackAfAmerican, :White], false, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_non_hispanic_client_explicit',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'counts the client in Multi-Racial (all other)' do
        report = run_report(questions: [question])
        # :multi_racial is cell B25
        count = report.answer(question: question, cell: 'B25')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client identifies with three races AND is NOT Hispanic/Latino' do
      before do
        household_id = 'race_multi_non_hispanic_explicit_2'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_multi_non_hispanic_explicit_2',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 },
          is_hoh: true,
        )
        test_client_attrs = build_race_attributes([:AmIndAKNative, :BlackAfAmerican, :White], false, all_primary_race_keys)
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_non_hispanic_client_explicit_2',
          household_id: household_id,
          race_attrs: test_client_attrs,
          is_hoh: false,
        )
      end

      it 'counts the client in Multi-Racial (all other)' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B25')
        expect(count.value).to eq(1)
      end
    end
  end

  # Tests for race and ethnicity breakdowns
end
