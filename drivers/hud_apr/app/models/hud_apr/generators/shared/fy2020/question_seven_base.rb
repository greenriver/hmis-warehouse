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

    private def q7a_persons_served # rubocop:disable Metrics/AbcSize
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

      # Number of adults
      answer = @report.answer(question: table_name, cell: 'B2')
      members = universe.members.where(a_t[:age].gteq(18))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adults w/ no children
      answer = @report.answer(question: table_name, cell: 'C2')
      members = universe.members.where(
        a_t[:age].gteq(18).
          and(a_t[:household_type].eq(:adults_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adults w/ children
      answer = @report.answer(question: table_name, cell: 'D2')
      members = universe.members.where(
        a_t[:age].gteq(18).
          and(a_t[:household_type].eq(:adults_and_children)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of adults in unknown household type
      answer = @report.answer(question: table_name, cell: 'F2')
      members = universe.members.where(
        a_t[:age].gteq(18).
          and(a_t[:household_type].eq(:unknown)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of children
      answer = @report.answer(question: table_name, cell: 'B3')
      members = universe.members.where(a_t[:age].lt(18))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of children w/ adults
      answer = @report.answer(question: table_name, cell: 'D3')
      members = universe.members.where(
        a_t[:age].lt(18).
          and(a_t[:household_type].eq(:adults_and_children)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of children w/ no adults
      answer = @report.answer(question: table_name, cell: 'E3')
      members = universe.members.where(
        a_t[:age].lt(18).
          and(a_t[:household_type].eq(:children_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of children in unknown household type
      answer = @report.answer(question: table_name, cell: 'F3')
      members = universe.members.where(
        a_t[:age].lt(18).
          and(a_t[:household_type].eq(:unknown)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of DK/R
      answer = @report.answer(question: table_name, cell: 'B4')
      members = universe.members.where(a_t[:dob_quality].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of DK/R w/ no children
      answer = @report.answer(question: table_name, cell: 'C4')
      members = universe.members.where(
        a_t[:dob_quality].in([8, 9]).
          and(a_t[:household_type].eq(:adults_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of DK/R w/ children
      answer = @report.answer(question: table_name, cell: 'D4')
      members = universe.members.where(
        a_t[:dob_quality].in([8, 9]).
          and(a_t[:household_type].eq(:adults_and_children)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of DK/R w/ no adults
      answer = @report.answer(question: table_name, cell: 'E4')
      members = universe.members.where(
        a_t[:dob_quality].in([8, 9]).
          and(a_t[:household_type].eq(:children_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of DK/R in unknown household type
      answer = @report.answer(question: table_name, cell: 'F4')
      members = universe.members.where(
        a_t[:dob_quality].in([8, 9]).
          and(a_t[:household_type].eq(:unknown)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of NC
      answer = @report.answer(question: table_name, cell: 'B5')
      members = universe.members.where(a_t[:dob_quality].eq(99))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of NC w/ no children
      answer = @report.answer(question: table_name, cell: 'C5')
      members = universe.members.where(
        a_t[:dob_quality].eq(99).
          and(a_t[:household_type].eq(:adults_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of NC w/ children
      answer = @report.answer(question: table_name, cell: 'D5')
      members = universe.members.where(
        a_t[:dob_quality].eq(99).
          and(a_t[:household_type].eq(:adults_and_children)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of NC w/ no adults
      answer = @report.answer(question: table_name, cell: 'E5')
      members = universe.members.where(
        a_t[:dob_quality].eq(99).
          and(a_t[:household_type].eq(:children_only)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of NC in unknown household type
      answer = @report.answer(question: table_name, cell: 'F5')
      members = universe.members.where(
        a_t[:dob_quality].eq(99).
          and(a_t[:household_type].eq(:unknown)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members
      answer.add_members(members)
      answer.update(summary: members.count)

      # Total w/ no children
      answer = @report.answer(question: table_name, cell: 'C6')
      members = universe.members.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Total w/ children
      answer = @report.answer(question: table_name, cell: 'D6')
      members = universe.members.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Total w/ no adults
      answer = @report.answer(question: table_name, cell: 'E6')
      members = universe.members.where(a_t[:household_type].eq(:children_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Total in unknown household type
      answer = @report.answer(question: table_name, cell: 'F6')
      members = universe.members.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)

      # PSH/RRH w/ move in date
      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:move_in_date].not_eq(nil)),
      )
      answer = @report.answer(question: table_name, cell: 'B7')
      members = ps_rrh_w_move_in
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ no children
      answer = @report.answer(question: table_name, cell: 'C7')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ children
      answer = @report.answer(question: table_name, cell: 'D7')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ no adults
      answer = @report.answer(question: table_name, cell: 'E7')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:children_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # in unknown household type
      answer = @report.answer(question: table_name, cell: 'F7')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)
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
        source_client = last_service_history_enrollment.source_client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          dob: source_client.DOB,
          dob_quality: source_client.DOBDataQuality,
          head_of_household: last_service_history_enrollment.head_of_household,
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
