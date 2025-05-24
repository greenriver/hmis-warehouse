# frozen_string_literal: true

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Race and Ethnicity Counts', type: :model do
  include_context 'HUD pit context'

  let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
  let(:es_project) { create_project(project_type: 0) } # ES-EE
  let(:adult_dob) { pit_date - 30.years }
  let(:child_dob) { pit_date - 5.years }

  # Helper to create a client with specific race/ethnicity flags and enroll them
  def create_and_enroll_client_for_race_test(uid:, household_id:, race_attrs:, is_hoh: true)
    client = create_client_with_warehouse_link(uid: uid, dob: is_hoh ? adult_dob : child_dob)
    client.update!(race_attrs)
    create_enrollment(
      client: client,
      project: es_project,
      entry_date: pit_date,
      relationship_to_ho_h: is_hoh ? 1 : 3,
      household_id: household_id,
    )
    client
  end

  describe 'American Indian, Alaska Native, or Indigenous (only)' do
    context 'when a client is AmIndAKNative only (not Hispanic/Latino)' do
      before do
        household_id = 'race_native_ak_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_ak',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 }, # A non-matching HoH
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_ak_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :native_ak is cell B11 for AdultAndChild question
        count = report.answer(question: question, cell: 'B11')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is AmIndAKNative and another race (not Hispanic/Latino)' do
      before do
        household_id = 'race_native_ak_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_ak_multi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_ak_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'does not count in AmIndAKNative (only), but in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        native_ak_only_count = report.answer(question: question, cell: 'B11')
        expect(native_ak_only_count.value).to eq(0)

        # :multi_racial in AdultAndChild.rb is B25 (title: 'Multi-Racial (all other)')
        # This corresponds to pit_race = 'Multi-Racial (not Hispanic/Latina/e/o)'
        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'American Indian, Alaska Native, or Indigenous & Hispanic/Latina/e/o' do
    context 'when a client is AmIndAKNative and Hispanic/Latino' do
      before do
        household_id = 'race_native_ak_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_ak_latino',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_ak_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :native_ak_latino is cell B12 for AdultAndChild question
        count = report.answer(question: question, cell: 'B12')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is AmIndAKNative, White, and Hispanic/Latino' do
      before do
        household_id = 'race_native_ak_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_ak_white_latino',
          household_id: household_id,
          race_attrs: { BlackAfAmerican: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_ak_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        native_ak_latino_count = report.answer(question: question, cell: 'B12')
        expect(native_ak_latino_count.value).to eq(0)

        # :multi_racial_latino is B24 for AdultAndChild
        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
      end
    end
  end

  describe 'Asian or Asian American (only)' do
    context 'when a client is Asian only (not Hispanic/Latino)' do
      before do
        household_id = 'race_asian_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_asian',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_asian_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :asian is cell B13 for AdultAndChild question
        count = report.answer(question: question, cell: 'B13')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Asian and another race (not Hispanic/Latino)' do
      before do
        household_id = 'race_asian_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_asian_multi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_asian_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        asian_only_count = report.answer(question: question, cell: 'B13')
        expect(asian_only_count.value).to eq(0)

        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'Asian or Asian American & Hispanic/Latina/e/o' do
    context 'when a client is Asian and Hispanic/Latino' do
      before do
        household_id = 'race_asian_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_asian_latino',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_asian_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :asian_latino is cell B14 for AdultAndChild question
        count = report.answer(question: question, cell: 'B14')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Asian, White, and Hispanic/Latino' do
      before do
        household_id = 'race_asian_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_asian_white_latino',
          household_id: household_id,
          race_attrs: { BlackAfAmerican: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_asian_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        asian_latino_count = report.answer(question: question, cell: 'B14')
        expect(asian_latino_count.value).to eq(0)

        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
      end
    end
  end

  describe 'Black, African American, or African (only)' do
    context 'when a client is Black/African American only (not Hispanic/Latino)' do
      before do
        household_id = 'race_black_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_black',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_black_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :black_af_american is cell B15 for AdultAndChild question
        count = report.answer(question: question, cell: 'B15')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Black/African American and another race (not Hispanic/Latino)' do
      before do
        household_id = 'race_black_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_black_multi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_black_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        black_only_count = report.answer(question: question, cell: 'B15')
        expect(black_only_count.value).to eq(0)

        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'Black, African American, or African & Hispanic/Latina/e/o' do
    context 'when a client is Black/African American and Hispanic/Latino' do
      before do
        household_id = 'race_black_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_black_latino',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_black_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :black_af_american_latino is cell B16 for AdultAndChild question
        count = report.answer(question: question, cell: 'B16')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Black/African American, White, and Hispanic/Latino' do
      before do
        household_id = 'race_black_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_black_white_latino',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 }, # HoH of a different race
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_black_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        black_latino_count = report.answer(question: question, cell: 'B16')
        expect(black_latino_count.value).to eq(0)

        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
      end
    end
  end

  describe 'Hispanic/Latina/e/o (only)' do
    context 'when a client is Hispanic/Latino only (no other race selected)' do
      before do
        household_id = 'race_latino_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_latino_only',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 }, # Non-Hispanic HoH
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_latino_only_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino, and no other race fields are 1
          },
          is_hoh: false
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
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_latino_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino AND White
          },
          is_hoh: false
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

  describe 'Middle Eastern or North African (only)' do
    context 'when a client is Middle Eastern/North African only (not Hispanic/Latino)' do
      before do
        household_id = 'race_mena_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_mena',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_mena_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 1,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :mid_east_na is cell B18 for AdultAndChild question
        count = report.answer(question: question, cell: 'B18')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Middle Eastern/North African and another race (not Hispanic/Latino)' do
      before do
        household_id = 'race_mena_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_mena_multi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_mena_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 1,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        mena_only_count = report.answer(question: question, cell: 'B18')
        expect(mena_only_count.value).to eq(0)

        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'Middle Eastern or North African & Hispanic/Latina/e/o' do
    context 'when a client is Middle Eastern/North African and Hispanic/Latino' do
      before do
        household_id = 'race_mena_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_mena_latino',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_mena_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 1,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :mid_east_na_latino is cell B19 for AdultAndChild question
        count = report.answer(question: question, cell: 'B19')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Middle Eastern/North African, White, and Hispanic/Latino' do
      before do
        household_id = 'race_mena_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_mena_white_latino',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_mena_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 1,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        mena_latino_count = report.answer(question: question, cell: 'B19')
        expect(mena_latino_count.value).to eq(0)

        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
      end
    end
  end

  describe 'Native Hawaiian or Pacific Islander (only)' do
    context 'when a client is Native Hawaiian/Pacific Islander only (not Hispanic/Latino)' do
      before do
        household_id = 'race_native_pi_only_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_pi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_pi_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :native_pi is cell B20 for AdultAndChild question
        count = report.answer(question: question, cell: 'B20')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Native Hawaiian/Pacific Islander and another race (not Hispanic/Latino)' do
      before do
        household_id = 'race_native_pi_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_pi_multi',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_pi_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        native_pi_only_count = report.answer(question: question, cell: 'B20')
        expect(native_pi_only_count.value).to eq(0)

        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'Native Hawaiian or Pacific Islander & Hispanic/Latina/e/o' do
    context 'when a client is Native Hawaiian/Pacific Islander and Hispanic/Latino' do
      before do
        household_id = 'race_native_pi_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_pi_latino',
          household_id: household_id,
          race_attrs: { White: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_pi_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :native_pi_latino is cell B21 for AdultAndChild question
        count = report.answer(question: question, cell: 'B21')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is Native Hawaiian/Pacific Islander, White, and Hispanic/Latino' do
      before do
        household_id = 'race_native_pi_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_native_pi_white_latino',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_native_pi_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 1, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        native_pi_latino_count = report.answer(question: question, cell: 'B21')
        expect(native_pi_latino_count.value).to eq(0)

        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
      end
    end
  end

  describe 'White (only)' do
    context 'when a client is White only (not Hispanic/Latino)' do
      before do
        household_id = 'race_white_only_1'
        # HoH can be anything for this test, as long as it allows the household to be processed
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_white',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 }, # Non-white, non-Hispanic HoH
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_white_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # Not Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :white is cell B22 for AdultAndChild question
        count = report.answer(question: question, cell: 'B22')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is White and another race (e.g., Asian) (not Hispanic/Latino)' do
      before do
        household_id = 'race_white_multi_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_white_multi',
          household_id: household_id,
          race_attrs: { BlackAfAmerican: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_white_asian_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial (not Hispanic/Latina/e/o)' do
        report = run_report(questions: [question])
        white_only_count = report.answer(question: question, cell: 'B22')
        expect(white_only_count.value).to eq(0)

        multi_racial_not_hispanic_count = report.answer(question: question, cell: 'B25')
        expect(multi_racial_not_hispanic_count.value).to eq(1)
      end
    end
  end

  describe 'White & Hispanic/Latina/e/o' do
    context 'when a client is White and Hispanic/Latino' do
      before do
        household_id = 'race_white_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_white_latino',
          household_id: household_id,
          race_attrs: { Asian: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_white_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts the client in the correct category' do
        report = run_report(questions: [question])
        # :white_latino is cell B23 for AdultAndChild question
        count = report.answer(question: question, cell: 'B23')
        expect(count.value).to eq(1)
      end
    end

    context 'when a client is White, Asian, and Hispanic/Latino' do
      before do
        household_id = 'race_white_asian_latino_1'
        create_and_enroll_client_for_race_test(
          uid: 'race_hoh_for_white_asian_latino',
          household_id: household_id,
          race_attrs: { BlackAfAmerican: 1, HispanicLatinaeo: 0 },
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_white_asian_latino_client',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
        )
      end

      it 'counts in Multi-Racial & Hispanic/Latina/e/o' do
        report = run_report(questions: [question])
        white_latino_count = report.answer(question: question, cell: 'B23')
        expect(white_latino_count.value).to eq(0)

        multi_racial_latino_count = report.answer(question: question, cell: 'B24')
        expect(multi_racial_latino_count.value).to eq(1)
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
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_latino_client_explicit',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 1, BlackAfAmerican: 0, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
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
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_latino_client_explicit_2',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 1, BlackAfAmerican: 1, NativeHIPacific: 0, White: 0, MidEastNAfrican: 0,
            HispanicLatinaeo: 1 # Is Hispanic/Latino
          },
          is_hoh: false
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
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_non_hispanic_client_explicit',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 0, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # NOT Hispanic/Latino
          },
          is_hoh: false
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
          is_hoh: true
        )
        create_and_enroll_client_for_race_test(
          uid: 'race_multi_non_hispanic_client_explicit_2',
          household_id: household_id,
          race_attrs: {
            AmIndAKNative: 1, Asian: 0, BlackAfAmerican: 1, NativeHIPacific: 0, White: 1, MidEastNAfrican: 0,
            HispanicLatinaeo: 0 # NOT Hispanic/Latino
          },
          is_hoh: false
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
