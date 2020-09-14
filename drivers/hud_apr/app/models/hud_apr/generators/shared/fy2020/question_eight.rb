###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEight < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q8'.freeze
    QUESTION_TABLE_NUMBERS = ['Q8a', 'Q8b'].freeze

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

      q8a_persons_served
      q8b_pit_count

      @report.complete(QUESTION_NUMBER)
    end

    private def q8a_persons_served
      a_t = report_client_universe.arel_table

      table_name = 'Q8a'
      metadata = {
        header_row: HEADER_ROW,
        row_labels: [
          'Total Households',
          'For PSH & RRH – the total households served who moved into housing',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Number of households
      heads_of_household = universe.members.where(a_t[:head_of_household].eq(true))

      answer = @report.answer(question: table_name, cell: 'B2')
      members = heads_of_household
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of households w/ no children
      answer = @report.answer(question: table_name, cell: 'C2')
      members = heads_of_household.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of households w/ children
      answer = @report.answer(question: table_name, cell: 'D2')
      members = heads_of_household.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of households w/ only children
      answer = @report.answer(question: table_name, cell: 'E2')
      members = heads_of_household.where(a_t[:household_type].eq(:only_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # Number of households in unknown household type
      answer = @report.answer(question: table_name, cell: 'F2')
      members = heads_of_household.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)

      # PSH/RRH w/ move in date
      ps_rrh_w_move_in = universe.members.where(
        a_t[:project_type].in([3, 13]).
          and(a_t[:head_of_household].eq(true)).
          and(a_t[:move_in_date].not_eq(nil)),
      )
      answer = @report.answer(question: table_name, cell: 'B3')
      members = ps_rrh_w_move_in
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ no children
      answer = @report.answer(question: table_name, cell: 'C3')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:adults_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ children
      answer = @report.answer(question: table_name, cell: 'D3')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:adults_and_children))
      answer.add_members(members)
      answer.update(summary: members.count)

      # w/ no adults
      answer = @report.answer(question: table_name, cell: 'E3')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:children_only))
      answer.add_members(members)
      answer.update(summary: members.count)

      # in unknown household type
      answer = @report.answer(question: table_name, cell: 'F3')
      members = ps_rrh_w_move_in.where(a_t[:household_type].eq(:unknown))
      answer.add_members(members)
      answer.update(summary: members.count)
    end

    private def q8b_pit_count
      table_name = 'Q8b'
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

      heads_of_household = universe.members.where(a_t[:head_of_household].eq(true))

      pit_date = pit_date(month: month, before: @report.end_date)
      psh_rrh_universe = heads_of_household.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:move_in_date].lteq(pit_date)).
          and(a_t[:project_type].in([3, 13])),
      )
      so_serv_ce_universe = heads_of_household.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gteq(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([4, 6, 14])),
      )
      other_universe = heads_of_household.where(
        a_t[:first_date_in_program].lteq(pit_date).
          and(a_t[:last_date_in_program].gt(pit_date).
            or(a_t[:last_date_in_program].eq(nil))).
          and(a_t[:project_type].in([1, 2, 3, 8, 9, 10, 13])),
      )

      psh_rrh_universe.or(so_serv_ce_universe).or(other_universe)
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
