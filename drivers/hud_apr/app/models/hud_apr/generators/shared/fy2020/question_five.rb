###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
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

    def run!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

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
          and(a_t[:age].gteq(18).
            or(a_t[:head_of_household].eq(true))),
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
      members = universe.members.where(a_t[:veteran_status].eq(1))
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
      # "...any adult stayer present when the head of household’s stay is 365 days or more,
      # even if that adult has not been in the household that long"
      answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: 'B16')
      hoh_ids = universe.members.where(
        a_t[:head_of_household].eq(true).
        and(a_t[:length_of_stay].gteq(365)),
      ).pluck(:head_of_household_id)
      members = universe.members.where(
        a_t[:head_of_household_id].in(hoh_ids).
          and(a_t[:age].gteq(18).
            or(a_t[:head_of_household].eq(true))),
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
            last_service_history_enrollment = clients_with_enrollments[client.id].last
            source_client = last_service_history_enrollment.source_client
            client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

            pending_associations[client] = report_client_universe.new(
              client_id: source_client.id,
              data_source_id: source_client.data_source_id,
              report_instance_id: @report.id,

              age: source_client.age_on(client_start_date),
              head_of_household: last_service_history_enrollment.head_of_household,
              head_of_household_id: last_service_history_enrollment.head_of_household_id,
              parenting_youth: last_service_history_enrollment.parenting_youth,
              first_date_in_program: last_service_history_enrollment.first_date_in_program,
              last_date_in_program: last_service_history_enrollment.last_date_in_program,
              veteran_status: source_client.VeteranStatus,
              length_of_stay: ((last_service_history_enrollment.last_date_in_program || @report.end_date + 1.day ) -
                last_service_history_enrollment.first_date_in_program).to_i,
              chronically_homeless: last_service_history_enrollment.enrollment.chronically_homeless_at_start?,
            )
          end
          report_client_universe.import(
            pending_associations.values,
            on_duplicate_key_update: {
              conflict_target: [:client_id, :data_source_id, :report_instance_id],
              columns: [
                :age,
                :head_of_household,
                :parenting_youth,
                :first_date_in_program,
                :last_date_in_program,
                :veteran_status,
                :length_of_stay,
                :chronically_homeless,
              ]
            }
          )
          universe_cell.add_universe_members(pending_associations)
        end
        universe_cell
      end
    end

    private def clients_with_enrollments(batch)
      GrdaWarehouse::ServiceHistoryEnrollment.
        entry
        in_project(@report.project_ids).
        joins(:enrollment).
        preload(enrollment: [:client, :disabilities, :current_living_situations]).
        where(client_id: batch.map(&:id)).
        group_by(&:client_id)
    end

    private def report_client_universe
      HudApr::Fy2020::AprClient
    end
  end
end
