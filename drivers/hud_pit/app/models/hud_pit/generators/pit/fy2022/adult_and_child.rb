###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPit::Generators::Pit::Fy2022
  class AdultAndChild < Base
    QUESTION_NUMBER = 'Households with at least one Adult & one Child'.freeze

    def self.filter_pending_associations(pending_associations)
      pending_associations.select { |row| row[:household_type] == :adults_and_children }
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_NUMBER])

      calculate

      @report.complete(QUESTION_NUMBER)
    end

    private def sub_calculations
      [
        {
          cell: 'B2', # Total Households in ES
          query: a_t[:project_type].eq(1).and(a_t[:relationship_to_hoh].eq(1)),
        },
        {
          cell: 'C2', # Total Households in TH
          query: a_t[:project_type].eq(2).and(a_t[:relationship_to_hoh].eq(1)),
        },
        {
          cell: 'D2', # Total Households in SO
          query: a_t[:project_type].eq(4).and(a_t[:relationship_to_hoh].eq(1)),
        },
        {
          cell: 'B3', # Total People in ES
          query: a_t[:project_type].eq(1),
        },
        {
          cell: 'C3', # Total People in TH
          query: a_t[:project_type].eq(2),
        },
        {
          cell: 'D3', # Total People in SO
          query: a_t[:project_type].eq(4),
        },
        {
          cell: 'B4', # Total Children in ES
          query: a_t[:project_type].eq(1).and(child_clause),
        },
        {
          cell: 'C4', # Total Children in TH
          query: a_t[:project_type].eq(2).and(child_clause),
        },
        {
          cell: 'D4', # Total Children in SO
          query: a_t[:project_type].eq(4).and(child_clause),
        },
        {
          cell: 'B5', # Total Youth in ES
          query: a_t[:project_type].eq(1).and(age_ranges['18-24']),
        },
        {
          cell: 'C5', # Total Youth in TH
          query: a_t[:project_type].eq(2).and(age_ranges['18-24']),
        },
        {
          cell: 'D5', # Total Youth in SO
          query: a_t[:project_type].eq(4).and(age_ranges['18-24']),
        },
        {
          cell: 'B5', # Total Non-Youth Adults in ES
          query: a_t[:project_type].eq(1).and(a_t[:age].gteq(25)),
        },
        {
          cell: 'C5', # Total Non-Youth Adults in TH
          query: a_t[:project_type].eq(2).and(a_t[:age].gteq(25)),
        },
        {
          cell: 'D5', # Total Non-Youth Adults in SO
          query: a_t[:project_type].eq(4).and(a_t[:age].gteq(25)),
        },
      ]
    end

    private def calculate
      table_name = QUESTION_NUMBER
      metadata = {
        header_row: [
          'Persons in Households with at least one Adult and one Child',
          'Emergency',
          'Transitional',
          'Outreach',
        ],
        row_labels: [
          'Total Number of Households',
          'Number of Persons (under age 18)',
          'Number of Persons (18 - 24)',
          'Number of Persons (over age 24)',
        ],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 19,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      sub_calculations.each do |calc|
        members = universe.members.where(calc[:query])
        answer = @report.answer(question: table_name, cell: calc[:cell])
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end
  end
end
