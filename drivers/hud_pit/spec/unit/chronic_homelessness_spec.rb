# frozen_string_literal: true

# drivers/hud_pit/spec/models/chronic_homelessness_spec.rb

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'Chronic Homelessness Calculations', type: :model do
  include_context 'HUD pit context'
  let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }

  describe 'Household Chronic Status' do
    context 'with HoH chronically homeless' do
      before do
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create household members
        @head_of_household = create_client_with_warehouse_link
        @child = create_client_with_warehouse_link(dob: '2020-06-01')
        @adult_member = create_client_with_warehouse_link

        # Create household ID
        household_id = 'test_household_123'

        # Create head of household enrollment with chronic status
        create_enrollment(
          client: @head_of_household,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 1,
          household_id: household_id,
        ).update!(
          # Add chronic status fields
          DateToStreetESSH: pit_date,
          LivingSituation: 116, # Place not meant for habitation
          MonthsHomelessPastThreeYears: 112, # 12+ months
          TimesHomelessPastThreeYears: 4, # 4+ times
          DisablingCondition: 1, # Yes
        )

        # Create child enrollment
        create_enrollment(
          client: @child,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 3,
          household_id: household_id,
        )

        # Create adult member enrollment
        create_enrollment(
          client: @adult_member,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 60.days,
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
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
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create household members
        @head_of_household = create_client_with_warehouse_link
        @chronic_adult = create_client_with_warehouse_link
        @child = create_client_with_warehouse_link(dob: '2020-06-01')

        # Create household ID
        household_id = 'test_household_123'

        # Create head of household enrollment (not chronically homeless)
        create_enrollment(
          client: @head_of_household,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )

        # Create chronically homeless adult enrollment
        create_enrollment(
          client: @chronic_adult,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 2,
          household_id: household_id,
        ).update!(
          DateToStreetESSH: pit_date - 1.year,
          LivingSituation: 116, # Place not meant for habitation
          MonthsHomelessPastThreeYears: 112, # 12+ months
          TimesHomelessPastThreeYears: 4, # 4+ times
          DisablingCondition: 1, # Yes
        )

        # Create child enrollment
        create_enrollment(
          client: @child,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 3,
          household_id: household_id,
        )
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
        # Create an ES project
        @es_project = create_project(project_type: 0) # ES-EE

        # Create household members
        @head_of_household = create_client_with_warehouse_link
        @child = create_client_with_warehouse_link(dob: '2020-06-01')

        # Create household ID
        household_id = 'test_household_123'

        # Create head of household enrollment with unknown chronic status
        create_enrollment(
          client: @head_of_household,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 1,
          household_id: household_id,
        ).update!(
          DateToStreetESSH: nil,
          LivingSituation: nil,
          MonthsHomelessPastThreeYears: nil,
          TimesHomelessPastThreeYears: nil,
          DisablingCondition: nil,
        )

        # Create child enrollment
        create_enrollment(
          client: @child,
          project: @es_project,
          entry_date: pit_date,
          exit_date: pit_date + 75.days,
          relationship_to_ho_h: 3,
          household_id: household_id,
        )
      end

      it 'children inherit HoH chronic status when HoH status is unknown' do
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
