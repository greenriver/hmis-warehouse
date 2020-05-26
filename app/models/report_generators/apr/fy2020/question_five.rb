###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::Apr::Fy2020
  class QuestionFive < HudReports::QuestionBase
    include ArelHelper

    QUESTION_NUMBER = 'Q5'
    QUESTION_TABLE_NUMBER = 'Q5a'

    TABLE_HEADER = []
    ROW_LABELS = [
      'Total number of persons served',
      'Number of adults (age 18 or over)',
      'Number of children (under age 18)',
      'Number of persons with unknown age',
      'Number of leavers',
      'Number of adult leavers',
      'Number of adult and head of household leavers',
      'Number of stayers',
      'Number of adult stayers',
      'Number of veterans',
      'Number of chronically homeless persons',
      'Number of youth under age 25',
      'Number of parenting youth under age 25 with children',
      'Number of adult heads of household',
      'Number of child and unknown-age heads of household',
      'Heads of households and adult stayers in the project 365 days or more',
    ]

    def initialize(generator)
      @generator = generator
      @report = generator.report
    end


    def self.question_number
      QUESTION_NUMBER
    end

    def run!
      @report.start(QUESTION_NUMBER)

      a_t = report_client_universe.arel_table

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'B',
        first_row: 1,
        last_row: 16,
      }
      @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      # Total clients
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B1')
      members = universe.universe_members
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adults
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B2')
      members = universe.members.where(a_t[:age].gteq(18))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of children
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B3')
      members = universe.members.where(a_t[:age].lt(18))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of unknown ages
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B4')
      members = universe.members.where(a_t[:age].eq(nil))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of leavers
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B5')
      members = universe.members.where(a_t[:last_date_in_program].lteq(@report.end_date))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adult leavers
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B6')
      members = universe.members.where(
        a_t[:last_date_in_program].lteq(@report.end_date).
          and(a_t[:age].gteq(18)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adult and HoH leavers
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B7')
      members = universe.members.where(
        a_t[:last_date_in_program].lteq(@report.end_date).
          and(a_t[:age].gteq(18)).
          and(a_t[:head_of_household].eq(true)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of stayers
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B8')
      members = universe.members.where(a_t[:last_date_in_program].gt(@report.end_date))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adult stayers
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B9')
      members = universe.members.where(
        a_t[:last_date_in_program].gt(@report.end_date).
          and(a_t[:age].gteq(18)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of veterans
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B10')
      members = universe.members.where(a_t[:veteran].eq(true))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of chronically homeless
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B11')
      members = universe.members.where(a_t[:chronically_homeless].eq(true))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of youth under 25
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B12')
      members = universe.members.where(
        a_t[:age].lt(25).
        and(a_t[:age].gteq(12)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of parenting youth under 25 with children
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B13')
      members = universe.members.where(
        a_t[:age].lt(25).
        and(a_t[:age].gteq(12)).
        and(a_t[:parenting_youth].eq(true)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adult HoH
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B14')
      members = universe.members.where(
        a_t[:age].gteq(18).
        and(a_t[:head_of_household].eq(true)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of child and unknown age HoH
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B15')
      members = universe.members.where(
        a_t[:age].lt(18).
        or(a_t[:age].eq(nil)).
        and(a_t[:head_of_household].eq(true)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # HoH and adult stayers in project 365 days or more
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B16')
      members = universe.members.where(
        a_t[:age].gteq(18).
        and(a_t[:head_of_household].eq(true)).
        and(a_t[:longest_stay].gteq(365)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      @report.complete(QUESTION_NUMBER)
    end

    private def universe
      @universe ||= begin
        universe_cell = @report.universe(QUESTION_NUMBER)

        @generator.client_scope.find_in_batches do |batch|
          pending_associations = {}

          clients_with_enrollments = clients_with_enrollments(batch)

          batch.each do |client|
            service_history_enrollments = clients_with_enrollments[client.id]

            earliest_start = service_history_enrollments.min { |x, y| x.first_date_in_program <=> y.first_date_in_program }
            latest_end_date = service_history_enrollments.map { |e| e.last_date_in_program || @report.end_date + 1.day }.max
            client_start_date = [@report.start_date, earliest_start.first_date_in_program].max
            head_of_household = service_history_enrollments.any? { |e| e.head_of_household }
            parenting_youth = service_history_enrollments.any? { |e| e.parenting_youth }
            veteran = client.veteran?
            longest_stay = service_history_enrollments.map do |e|
              ((e.last_date_in_program || @report.end_date + 1.day )- e.first_date_in_program).to_i
            end.max

            pending_associations[client] = report_client_universe.new(
              age: client.age_on(client_start_date),
              head_of_household: head_of_household,
              parenting_youth: parenting_youth,
              first_date_in_program: earliest_start.first_date_in_program,
              last_date_in_program: latest_end_date,
              veteran: veteran,
              longest_stay: longest_stay,
              chronically_homeless: earliest_start.enrollment.chronically_homeless_at_start?,
            )
          end
          report_client_universe.import(pending_associations.values)
          universe_cell.add_universe_members(pending_associations)
        end
        universe_cell
      end
    end

    private def clients_with_enrollments(batch)
      GrdaWarehouse::ServiceHistoryEnrollment.
        in_project(@report.project_ids).
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations]).
        where(client_id: batch.map(&:id)).
        group_by(&:client_id)
    end

    private def report_client_universe
      HudReports::AprClient
    end

  end
end
