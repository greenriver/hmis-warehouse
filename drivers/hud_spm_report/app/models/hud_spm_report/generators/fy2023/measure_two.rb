###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# HUD SPM Report Generator: Measure 2a and 2b: The Extent to which Persons Who Exit Homelessness
# to Permanent Housing Destinations Return to Homelessness within 6, 12,
# and 24 months.
module HudSpmReport::Generators::Fy2023
  class MeasureTwo < MeasureBase
    def self.question_number
      'Measure 2'.freeze
    end

    def self.client_class
      HudSpmReport::Fy2023::Return.
        left_outer_joins(:exit_enrollment, :return_enrollment).
        preload(exit_enrollment: { enrollment: :project }, return_enrollment: { enrollment: :project })
    end

    def self.table_descriptions
      {
        'Measure 2' => 'The Extent to which Persons Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months',
        # '2a and 2b' => 'The Extent to which Persons Who Exit Homelessness to Permanent Housing Destinations Return to Homelessness within 6, 12, and 24 months.',
      }.freeze
    end

    def run_question!
      tables = [
        ['2a and 2b', :run_2a_and_b],
      ]

      @report.start(self.class.question_number, tables.map(&:first))

      tables.each do |name, msg|
        send(msg, name)
      end

      @report.complete(self.class.question_number)
    end

    COLUMNS = {
      'B' => 'Total Number of Persons who Exited to a Permanent Housing Destination (2 Years Prior)',
      'C' => 'Number Returning to Homelessness in Less than 6 Months (0 - 180 days)',
      'D' => 'Percentage of Returns in Less than 6 Months (0 - 180 days)',
      'E' => 'Number Returning to Homelessness from 6 to 12 Months (181 - 365 days)',
      'F' => 'Percentage of Returns from 6 to 12 Months (181 - 365 days)',
      'G' => 'Number Returning to Homelessness from 13 to 24 Months (366 - 730 days)',
      'H' => 'Percentage of Returns from 13 to 24 Months (366 - 730 days)',
      'I' => 'Number of Returns in 2 Years',
      'J' => 'Percentage of Returns in 2 Years',
    }.freeze

    private def run_2a_and_b(table_name)
      prepare_table(
        table_name,
        {
          2 => 'Exit was from SO',
          3 => 'Exit was from ES',
          4 => 'Exit was from TH',
          5 => 'Exit was from SH',
          6 => 'Exit was from PH',
          7 => 'TOTAL Returns to Homelessness',
        },
        COLUMNS,
      )

      members = create_universe(table_name)
      totals = {
        B: 0,
        C: 0,
        E: 0,
        G: 0,
        I: 0,
      }
      total_answers = {
        B: @report.answer(question: table_name, cell: 'B7'),
        C: @report.answer(question: table_name, cell: 'C7'),
        E: @report.answer(question: table_name, cell: 'E7'),
        G: @report.answer(question: table_name, cell: 'G7'),
        I: @report.answer(question: table_name, cell: 'I7'),
      }

      report_rows.each do |row_number, project_type|
        candidates_for_row = members.where(a_t[:project_type].in(project_type))
        answer = @report.answer(question: table_name, cell: 'B' + row_number.to_s)
        answer.add_members(candidates_for_row)
        total_answers[:B].add_members(candidates_for_row)
        row_count = candidates_for_row.count
        totals[:B] += row_count
        answer.update(summary: row_count)

        report_columns.each do |count_column, (percent_column, query)|
          answer = @report.answer(question: table_name, cell: count_column.to_s + row_number.to_s)
          included = candidates_for_row.where(query)
          answer.add_members(included)
          total_answers[count_column].add_members(included)
          included_count = included.count
          totals[count_column] += included_count
          answer.update(summary: included_count)

          answer = @report.answer(question: table_name, cell: percent_column.to_s + row_number.to_s)
          answer.update(summary: percent(included_count, row_count))
        end
      end

      totals.keys.each do |count_column|
        answer = @report.answer(question: table_name, cell: count_column.to_s + '7')
        answer.update(summary: totals[count_column])

        next if count_column == :B # B is the denominator, so don't calculate percentage

        answer = @report.answer(question: table_name, cell: count_column.next.to_s + '7')
        answer.update(summary: percent(totals[count_column], totals[:B]))
      end
    end

    private def a_t
      @a_t ||= HudSpmReport::Fy2023::Return.arel_table
    end

    private def report_rows
      {
        2 => HudUtility2024.project_type_number_from_code(:so),
        3 => HudUtility2024.project_type_number_from_code(:es),
        4 => HudUtility2024.project_type_number_from_code(:th),
        5 => HudUtility2024.project_type_number_from_code(:sh),
        6 => HudUtility2024.project_type_number_from_code(:ph),
      }.freeze
    end

    private def report_columns
      {
        # TODO: can days_to_return really be 0, or should it start with 1?
        C: [:D, a_t[:days_to_return].between(0..180)],
        E: [:F, a_t[:days_to_return].between(181..365)],
        G: [:H, a_t[:days_to_return].between(366..730)],
        I: [:J, a_t[:days_to_return].between(0..730)],
      }.freeze
    end

    private def create_universe(table_name)
      @universe = @report.universe(table_name)
      returns = HudSpmReport::Fy2023::Return.compute_returns(@report, enrollment_set)

      members = returns.map do |enrollment|
        [enrollment.client, enrollment]
      end.to_h
      @universe.add_universe_members(members)

      @universe.members
    end
  end
end
