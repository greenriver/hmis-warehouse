###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2021
  class QuestionThree < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 3'.freeze
    QUESTION_TABLE_NUMBER = 'Q3'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 3' => 'Universal Data Elements',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    private def run_question! # rubocop:disable Metrics/AbcSize
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: [
          'Data Element',
          'Error Count',
          '% of Error Rate',
        ],
        row_labels: [
          'Veteran Status (3.07)',
          'Project Start Date (3.10)',
          'Relationship to Head of Household (3.15)',
          'Client Location (3.16)',
          'Disabling Condition (3.08)',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # veteran status
      answer = @report.answer(question: table_name, cell: 'B2')
      members = universe.members.where(
        a_t[:veteran_status].in([8, 9, 99]).
          or(a_t[:veteran_status].eq(nil)).
          or(a_t[:veteran_status].eq(1).
            and(a_t[:age].lt(18))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      # Only adults are in the population of possible veterans
      # Add the minors who claim veteran status to ensure that the error rate cannot be greater than 100%
      veteran_denominator = universe.members.where(adult_clause.or(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))))
      answer.update(summary: percentage(members.count / veteran_denominator.count.to_f))

      # project start date
      answer = @report.answer(question: table_name, cell: 'B3')
      members = universe.members.where(a_t[:overlapping_enrollments].not_eq([]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))

      # relationship to head of household
      answer = @report.answer(question: table_name, cell: 'B4')
      households_with_multiple_hohs = []
      households_with_no_hoh = []

      universe.members.preload(:universe_membership).find_each do |member|
        apr_client = member.universe_membership
        count_of_heads = apr_client.household_members.select { |household_member| household_member['relationship_to_hoh'] == 1 }.count
        households_with_multiple_hohs << apr_client.household_id if count_of_heads > 1
        households_with_no_hoh << apr_client.household_id if count_of_heads.zero?
      end

      members = universe.members.where(
        a_t[:relationship_to_hoh].not_in((1..5).to_a).
          or(a_t[:relationship_to_hoh].eq(nil)).
          or(a_t[:household_id].in(households_with_multiple_hohs)).
          or(a_t[:household_id].in(households_with_no_hoh)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))

      # client location
      answer = @report.answer(question: table_name, cell: 'B5')
      members = universe.members.
        where(hoh_clause).
        where(
          a_t[:enrollment_coc].eq(nil).
            or(a_t[:enrollment_coc].not_in(HUD.cocs.keys)),
        )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      hoh_denominator = universe.members.where(hoh_clause)
      answer.update(summary: percentage(members.count / hoh_denominator.count.to_f))

      # disabling condition
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members.where(
        a_t[:disabling_condition].in([8, 9, 99]).
          or(a_t[:disabling_condition].eq(nil)).
          or(a_t[:disabling_condition].eq(0).
            and(a_t[:indefinite_and_impairs].eq(true).
              and(a_t[:developmental_disability].eq(true).
                or(a_t[:hiv_aids].eq(true)).
                or(a_t[:physical_disability].eq(true)).
                or(a_t[:chronic_disability].eq(true)).
                or(a_t[:mental_health_problem].eq(true)).
                or(a_t[:substance_abuse].eq(true)).
                or(a_t[:indefinite_and_impairs].eq(true))))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C6')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))

      @report.complete(QUESTION_NUMBER)
    end
  end
end
