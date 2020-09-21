###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSevenBase < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 7'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    protected def header_row
      [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ].freeze
    end

    private def q7a_persons_served
      table_name = 'Q7a'
      metadata = {
        header_row: header_row,
        row_labels: [
          'Adults',
          'Children',
          'Client Doesn’t Know/ Client Refused',
          'Data Not Collected',
          'Total',
          'For PSH & RRH – the total persons served who moved into housing',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      [
        # Number of adults
        {
          cell: 'B2',
          clause: adult_clause,
        },
        # Number of adults w/ no children
        {
          cell: 'C2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of adults w/ children
        {
          cell: 'D2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of adults in unknown household type
        {
          cell: 'F2',
          clause: adult_clause.
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of children
        {
          cell: 'B3',
          clause: child_clause,
        },
        # Number of children w/ adults
        {
          cell: 'D3',
          clause: child_clause.
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of children w/ no adults
        {
          cell: 'E3',
          clause: child_clause.
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of children in unknown household type
        {
          cell: 'F3',
          clause: child_clause.
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of DK/R
        {
          cell: 'B4',
          clause: a_t[:dob_quality].in([8, 9]),
        },
        # Number of DK/R w/ no children
        {
          cell: 'C4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of DK/R w/ children
        {
          cell: 'D4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of DK/R w/ no adults
        {
          cell: 'E4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of DK/R in unknown household type
        {
          cell: 'F4',
          clause: a_t[:dob_quality].in([8, 9]).
            and(a_t[:household_type].eq(:unknown)),
        },
        # Number of NC
        {
          cell: 'B5',
          clause: a_t[:dob_quality].eq(99),
        },
        # Number of NC w/ no children
        {
          cell: 'C5',
          clause: a_t[:dob_quality].eq(99).
            and(a_t[:household_type].eq(:adults_only)),
        },
        # Number of NC w/ children
        {
          cell: 'D5',
          clause: a_t[:dob_quality].eq(99).
            and(a_t[:household_type].eq(:adults_and_children)),
        },
        # Number of NC w/ no adults
        {
          cell: 'E5',
          clause: a_t[:dob_quality].eq(99).
            and(a_t[:household_type].eq(:children_only)),
        },
        # Number of NC in unknown household type
        {
          cell: 'F5',
          clause: a_t[:dob_quality].eq(99).
            and(a_t[:household_type].eq(:unknown)),
        },
        # Total
        {
          cell: 'B6',
          clause: Arel.sql('1=1'),
        },
        # Total w/ no children
        {
          cell: 'C6',
          clause: a_t[:household_type].eq(:adults_only),
        },
        # Total w/ children
        {
          cell: 'D6',
          clause: a_t[:household_type].eq(:adults_and_children),
        },
        # Total w/ no adults
        {
          cell: 'E6',
          clause: a_t[:household_type].eq(:children_only),
        },
        # Total in unknown household type
        {
          cell: 'F6',
          clause: a_t[:household_type].eq(:unknown),
        },
        {
          cell: 'B5',
          clause: a_t[:dob_quality].eq(99),
        },
        {
          cell: 'B5',
          clause: a_t[:dob_quality].eq(99),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = universe.members.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:move_in_date].not_eq(nil)),
      )
      [
        # PSH/RRH w/ move in date
        {
          cell: 'B7',
          clause: Arel.sql('1=1'),
        },
        # w/ no children
        {
          cell: 'C7',
          clause: a_t[:household_type].eq(:adults_only),
        },
        # w/ children
        {
          cell: 'D7',
          clause: a_t[:household_type].eq(:adults_and_children),
        },
        # w/ no adults
        {
          cell: 'E7',
          clause: a_t[:household_type].eq(:children_only),
        },
        # in unknown household type
        {
          cell: 'F7',
          clause: a_t[:household_type].eq(:unknown),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = ps_rrh_w_move_in.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end

    private def universe
      batch_initializer = ->(clients_with_enrollments) do
        @household_types = {}
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = last_service_history_enrollment.household_id
          @household_types[hh_id] = household_makeup(hh_id, [@report.start_date, last_service_history_enrollment.first_date_in_program].max)
        end
      end

      @universe ||= build_universe(QUESTION_NUMBER, before_block: batch_initializer) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          dob: source_client.DOB,
          dob_quality: source_client.DOBDataQuality,
          head_of_household: last_service_history_enrollment[:head_of_household],
          household_id: last_service_history_enrollment.household_id,
          project_type: last_service_history_enrollment.project_type,
          move_in_date: last_service_history_enrollment.move_in_date,
          household_type: @household_types[last_service_history_enrollment.household_id],
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
