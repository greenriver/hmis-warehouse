###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2020
  class QuestionFive < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 5'.freeze
    QUESTION_TABLE_NUMBER = 'Q5'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: [
          'Entering into project type',
          'Count of total records',
          'Missing time in institution (3.917.2)',
          'Missing time in housing (3.917.2)',
          'Approximate Date started (3.917.3) DK/R/missing',
          'Number of times (3.917.4) DK/R/missing',
          'Number of months (3.917.5) DK/R/missing',
          '% of records unable to calculate',
        ],
        row_labels: [
          'ES, SH, Street Outreach',
          'TH',
          'PH (all)',
          'Total',
        ],
        first_column: 'B',
        last_column: 'H',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      adults_and_hohs = universe.members.where(
        a_t[:first_date_in_program].gt(Date.parse('2016-10-01')).
          and(a_t[:age].gteq(18).
            or(a_t[:head_of_household].eq(true).
              and(a_t[:age].lt(18).
                or(a_t[:age].eq(nil))))),
      )

      es_sh_so_clients = es_sh_so(table_name, adults_and_hohs)
      th_clients = th(table_name, adults_and_hohs)
      ph_clients = ph(table_name, adults_and_hohs)

      # totals
      answer = @report.answer(question: table_name, cell: 'B5')
      answer.update(summary: adults_and_hohs.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H5')
      total_members = es_sh_so_clients.
        or(th_clients).
        or(ph_clients)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)
      answer.update(summary: percentage(total_members.count / adults_and_hohs.count.to_f))

      @report.complete(QUESTION_NUMBER)
    end

    private def es_sh_so(table_name, adults_and_hohs)
      es_sh_so = adults_and_hohs.where(a_t[:project_type].in([1, 4, 8]))

      # count
      answer = @report.answer(question: table_name, cell: 'B2')
      members = es_sh_so
      answer.add_members(members)
      answer.update(summary: members.count)

      # date homeless missing
      answer = @report.answer(question: table_name, cell: 'E2')
      date_homeless_members = es_sh_so.where(a_t[:date_homeless].eq(nil))
      answer.add_members(date_homeless_members)
      answer.update(summary: date_homeless_members.count)

      # times homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'F2')
      times_homeless_members = es_sh_so.where(a_t[:times_homeless].in([nil, 8, 9]))
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G2')
      months_homeless_members = es_sh_so.where(a_t[:months_homeless].in([nil, 8, 9]))
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H2')
      members = date_homeless_members.
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: percentage(members.count / es_sh_so.count.to_f))

      members
    end

    private def th(table_name, adults_and_hohs)
      th = adults_and_hohs.where(a_t[:project_type].eq(2))
      th_buckets = [
        # count
        {
          cell: 'B3',
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # date homeless missing
        {
          cell: 'C3',
          clause: a_t[:date_homeless].eq(nil),
          include_in_percent: true,
        },
        # missing time in institution
        {
          cell: 'D3',
          clause: a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
            and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
          include_in_percent: true,
        },
        # missing time in housing
        {
          cell: 'E3',
          clause: a_t[:prior_living_situation].in([nil, 29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
            and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: 'F3',
          clause: a_t[:times_homeless].in([nil, 8, 9]),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: 'G3',
          clause: a_t[:months_homeless].in([nil, 8, 9]),
          include_in_percent: true,
        },
      ]
      th_buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = th.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: 'H3')
      ors = th_buckets.select { |m| m[:include_in_percent] }.map do |cell|
        cell[:clause].to_sql
      end
      members = th.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / th.count.to_f))

      members
    end

    private def ph(table_name, adults_and_hohs)
      ph = adults_and_hohs.where(a_t[:project_type].in([3, 9, 10, 13]))

      ph_buckets = [
        # count
        {
          cell: 'B4',
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # date homeless missing
        {
          cell: 'C4',
          clause: a_t[:date_homeless].eq(nil),
          include_in_percent: true,
        },
        # missing time in institution
        {
          cell: 'D4',
          clause: a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
            and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
          include_in_percent: true,
        },
        # missing time in housing
        {
          cell: 'E4',
          clause: a_t[:prior_living_situation].in([nil, 29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
            and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: 'F4',
          clause: a_t[:times_homeless].in([nil, 8, 9]),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: 'G4',
          clause: a_t[:months_homeless].in([nil, 8, 9]),
          include_in_percent: true,
        },
      ]
      ph_buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = ph.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: 'H4')
      ors = ph_buckets.select { |m| m[:include_in_percent] }.map do |cell|
        cell[:clause].to_sql
      end
      members = ph.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / ph.count.to_f))

      members
    end
  end
end
