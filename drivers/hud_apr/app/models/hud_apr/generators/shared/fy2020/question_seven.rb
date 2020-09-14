###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSeven < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q7'.freeze
    QUESTION_TABLE_NUMBERS = ['Q7a', 'Q7b'].freeze

    HEADER_ROW = [
      ' ',
      'Total',
      'Without Children',
      'With Children and Adults',
      'With Only Children',
      'Unknown Household Type',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q7a_persons_served
      q7b_pit_count

      @report.complete(QUESTION_NUMBER)
    end

    private def q7a_persons_served # rubocop:disable Metrics/AbcSize
      a_t = report_client_universe.arel_table

      table_name = 'Q7a'
      metadata = {
        header_row: HEADER_ROW,
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

    private def q7b_pit_count
      table_name = 'Q7b'
      metadata = {
        header_row: HEADER_ROW,
        row_labels: [
          'January',
          'April',
          'July',
          'October',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      pit_row(month: 1, table_name: table_name, row: 2)
      pit_row(month: 4, table_name: table_name, row: 3)
      pit_row(month: 7, table_name: table_name, row: 4)
      pit_row(month: 10, table_name: table_name, row: 5)
    end

    private def pit_row(month:, table_name:, row:)
      a_t = report_client_universe.arel_table
      row_universe = pit_universe(month: month)

      # Total
      answer = @report.answer(question: table_name, cell: 'B' + row.to_s)
      members = row_universe
      answer.add_members(members)
      answer.update(summary: members.count)

      # Without children
      answer = @report.answer(question: table_name, cell: 'C' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      #  Adults and children
      answer = @report.answer(question: table_name, cell: 'D' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Without adults
      answer = @report.answer(question: table_name, cell: 'E' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:children_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Unknown family type
      answer = @report.answer(question: table_name, cell: 'F' + row.to_s)
      members = row_universe.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)
    end

    private def pit_universe(month:)
      a_t = report_client_universe.arel_table

      pit_date = pit_date(month: month, before: @report.end_date)
      psh_rrh_universe = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:move_in_date].lteq(pit_date)).
          and(a_t[:project_type].in([3, 13])),
      )
      so_serv_ce__universe = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gteq(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([4, 6, 14])),
      )
      other_universe = universe.members.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([2, 3, 8, 9, 10, 13])),
      )

      psh_rrh_universe.or(so_serv_ce__universe).or(other_universe)
    end

    private def pit_date(month:, before:)
      year = before.year if month < before.month
      year = before.year if month == before.month && before.day >= last_wednesday_of(month: before.month, year: before.year)
      year = before.year - 1 if month > before.month
      year = before.year - 1 if month == before.month && before.day < last_wednesday_of(month: before.month, year: before.year)

      last_wednesday_of(month: month, year: year)
    end

    private def last_wednesday_of(month:, year:)
      date = Date.new(year, month, -1) # end of the month
      date = date.prev_day until date.wednesday?

      date
    end

    private def universe
      batch_initializer = ->(clients_with_enrollments) do
        household_members = {}
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          household_members[last_service_history_enrollment.household_id] ||= []
          household_members[last_service_history_enrollment.household_id] << last_service_history_enrollment
        end

        @household_types = household_members.transform_values do |enrollments|
          next :adults_and_children if adults?(enrollments) && children?(enrollments)
          next :adults_only if adults?(enrollments) && ! children?(enrollments) && ! unknown_ages?(enrollments)
          next :children_only if children?(enrollments) && ! adults?(enrollments) && ! unknown_ages?(enrollments)

          :unknown
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

    private def adults?(enrollments)
      enrollments.any? do |enrollment|
        source_client = enrollment.source_client
        client_start_date = [@report.start_date, enrollment.first_date_in_program].max
        age = source_client.age_on(client_start_date)
        next false if age.blank?

        age >= 18
      end
    end

    private def children?(enrollments)
      enrollments.any? do |enrollment|
        source_client = enrollment.source_client
        client_start_date = [@report.start_date, enrollment.first_date_in_program].max
        age = source_client.age_on(client_start_date)
        next false if age.blank?

        age < 18
      end
    end

    private def unknown_ages?(enrollments)
      enrollments.any? do |enrollment|
        enrollment.source_client.DOB.blank?
      end
    end
  end
end
