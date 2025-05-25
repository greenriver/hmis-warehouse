# frozen_string_literal: true

# drivers/hud_pit/spec/models/chronic_homelessness_spec.rb

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'Chronic Homelessness Calculations', type: :model do
  include_context 'HUD pit context'
  let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
  let(:es_project) { create_project(project_type: 0) } # ES-EE
  let(:adult_dob) { pit_date - 30.years }
  let(:child_dob) { pit_date - 5.years } # Standardized child DOB

  # Helper to set up a household member with potential chronic homelessness status
  def setup_household_member(uid_suffix:, dob:, rel_to_hoh:, household_id:, exit_offset_days:, ch_profile: :default, custom_ch_attrs: {})
    client = create_client_with_warehouse_link(uid: "client_ch_#{uid_suffix}", dob: dob)
    enrollment = create_enrollment(
      client: client,
      project: es_project,
      entry_date: pit_date,
      exit_date: pit_date + exit_offset_days.days,
      relationship_to_ho_h: rel_to_hoh,
      household_id: household_id,
    )

    ch_attributes_to_apply = {}
    case ch_profile
    when :chronic
      ch_attributes_to_apply = {
        DateToStreetESSH: pit_date - 1.year, # Default CH start, ensuring >12 months before pit_date if needed for logic
        LivingSituation: 116, # Place not meant for habitation
        MonthsHomelessPastThreeYears: 112, # 12+ months
        TimesHomelessPastThreeYears: 4, # 4+ times
        DisablingCondition: 1, # Yes
      }
    when :unknown
      ch_attributes_to_apply = {
        DateToStreetESSH: nil, LivingSituation: nil, MonthsHomelessPastThreeYears: nil,
        TimesHomelessPastThreeYears: nil, DisablingCondition: nil
      }
    when :explicitly_not_chronic # For members explicitly stated as not CH
      ch_attributes_to_apply = {
        DateToStreetESSH: pit_date - 10.days, # Example: Homeless recently but not long-term
        LivingSituation: 101, # e.g., Emergency shelter
        MonthsHomelessPastThreeYears: 1, # e.g., 1 month
        TimesHomelessPastThreeYears: 1, # e.g., 1 time
        DisablingCondition: 0, # No
      }
      # if :default, no attributes are applied, relying on factory/create_enrollment defaults (presumably not chronic)
    end

    enrollment.update!(ch_attributes_to_apply.merge(custom_ch_attrs)) if ch_attributes_to_apply.present?
    client
  end

  describe 'Household Chronic Status' do
    let(:household_id) { 'test_household_ch_123' } # Common household_id for these contexts

    context 'with HoH chronically homeless' do
      before do
        setup_household_member(uid_suffix: 'hoh_ch', dob: adult_dob, rel_to_hoh: 1, household_id: household_id, exit_offset_days: 75, ch_profile: :chronic)
        setup_household_member(uid_suffix: 'child_in_hoh_ch_hh', dob: child_dob, rel_to_hoh: 3, household_id: household_id, exit_offset_days: 75)
        setup_household_member(uid_suffix: 'adult_in_hoh_ch_hh', dob: adult_dob, rel_to_hoh: 2, household_id: household_id, exit_offset_days: 60)
      end

      it 'marks entire household as chronically homeless when HoH is chronically homeless' do
        report = run_report(questions: [question])

        expect(report.universe(question).members.count).to eq(3)

        total_households = report.answer(question: question, cell: 'B2')
        expect(total_households.value).to eq(1)

        total_persons = report.answer(question: question, cell: 'B3')
        expect(total_persons.value).to eq(3)

        chronic_households = report.answer(question: question, cell: 'B26')
        expect(chronic_households.value).to eq(1)

        chronic_persons = report.answer(question: question, cell: 'B27')
        expect(chronic_persons.value).to eq(3)
      end
    end

    context 'with non-HoH adult chronically homeless' do
      before do
        setup_household_member(uid_suffix: 'hoh_in_non_hoh_ch_hh', dob: adult_dob, rel_to_hoh: 1, household_id: household_id, exit_offset_days: 75, ch_profile: :explicitly_not_chronic) # HoH is not CH
        setup_household_member(uid_suffix: 'chronic_adult_member', dob: adult_dob, rel_to_hoh: 2, household_id: household_id, exit_offset_days: 75, ch_profile: :chronic)
        setup_household_member(uid_suffix: 'child_in_non_hoh_ch_hh', dob: child_dob, rel_to_hoh: 3, household_id: household_id, exit_offset_days: 75)
      end

      it 'marks entire household as chronically homeless when any adult is chronically homeless' do
        report = run_report(questions: [question])

        expect(report.universe(question).members.count).to eq(3)

        total_households = report.answer(question: question, cell: 'B2')
        expect(total_households.value).to eq(1)

        total_persons = report.answer(question: question, cell: 'B3')
        expect(total_persons.value).to eq(3)

        chronic_households = report.answer(question: question, cell: 'B26')
        expect(chronic_households.value).to eq(1)

        chronic_persons = report.answer(question: question, cell: 'B27')
        expect(chronic_persons.value).to eq(3)
      end
    end

    context 'with HoH having unknown chronic status' do
      before do
        setup_household_member(uid_suffix: 'hoh_unknown_ch', dob: adult_dob, rel_to_hoh: 1, household_id: household_id, exit_offset_days: 75, ch_profile: :unknown)
        setup_household_member(uid_suffix: 'child_in_hoh_unknown_ch_hh', dob: child_dob, rel_to_hoh: 3, household_id: household_id, exit_offset_days: 75)
      end

      it 'children inherit HoH chronic status when HoH status is unknown' do
        # This expectation implies that if HoH is 'unknown CH', they (and thus household) are NOT CH.
        report = run_report(questions: [question])
        expect(report.universe(question).members.count).to eq(2)

        total_households = report.answer(question: question, cell: 'B2')
        expect(total_households.value).to eq(1)

        total_persons = report.answer(question: question, cell: 'B3')
        expect(total_persons.value).to eq(2)

        chronic_households = report.answer(question: question, cell: 'B26')
        expect(chronic_households.value).to eq(0)

        chronic_persons = report.answer(question: question, cell: 'B27')
        expect(chronic_persons.value).to eq(0)
      end
    end
  end
end
