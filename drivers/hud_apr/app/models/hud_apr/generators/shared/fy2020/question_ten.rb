###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 10'.freeze
    QUESTION_TABLE_NUMBERS = ['Q10a', 'Q10b', 'Q10c', 'Q10d'].freeze

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def table_rows
      {
        'Male' => [2, a_t[:gender].eq(1)],
        'Female' => [3, a_t[:gender].eq(0)],
        'Trans Female (MTF or Male to Female)' => [4, a_t[:gender].eq(2)],
        'Trans Male (FTM or Female to Male)' => [5, a_t[:gender].eq(3)],
        'Gender Non-Conforming (i.e. not exclusively male or female)' => [6, a_t[:gender].eq(4)],
        'Client Doesn\'t Know/Client Refused' => [7, a_t[:gender].in([8, 9])],
        'Data Not Collected' => [8, a_t[:gender].eq(99)],
        'Subtotal' => [9, Arel.sql('1=1')],
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    private def q10a_gender_of_adults
      table_name = 'Q10a'
      header_row = [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_only),
        'D' => a_t[:household_type].eq(:adults_and_children),
        'E' => a_t[:household_type].eq(:unknown),
      }

      generate_table(table_name, adult_clause, header_row, columns)
    end

    private def q10b_gender_of_children
      table_name = 'Q10b'
      header_row = [
        ' ',
        'Total',
        'With Children and Adults',
        'With Only Children',
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_and_children),
        'D' => a_t[:household_type].eq(:children_only),
        'E' => a_t[:household_type].eq(:unknown),
      }

      generate_table(table_name, child_clause, header_row, columns)
    end

    private def q10c_gender_of_missing_age
      table_name = 'Q10c'
      header_row = [
        ' ',
        'Total',
        'Without Children',
        'With Children and Adults',
        "With Only Children",
        'Unknown Household Type',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:household_type].eq(:adults_only),
        'D' => a_t[:household_type].eq(:adults_and_children),
        'E' => a_t[:household_type].eq(:children_only),
        'F' => a_t[:household_type].eq(:unknown),
      }

      no_age_clause = a_t[:age].eq(nil)
      generate_table(table_name, no_age_clause, header_row, columns)
    end

    private def q10d_gender_by_age_range
      header_row = [
        ' ',
        'Total',
        'Under Age 18',
        'Age 18-24',
        'Age 25-61',
        'Age 62 and over',
        'Client Doesn\'t Know/Client Refused',
        'Data Not Collected',
      ]
      columns = {
        'B' => Arel.sql('1=1'),
        'C' => a_t[:age].between(0..17),
        'D' => a_t[:age].between(18..24),
        'E' => a_t[:age].between(25..61),
        'F' => a_t[:age].gteq(62),
        'G' => a_t[:dob_quality].in([8, 9]),
        'H' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
      }.freeze

      active_clients = Arel.sql('1=1')
      generate_table(table_name, active_clients, header_row, columns)
    end

    private def generate_table(table_name, universe_clause, header_row, columns)
      metadata = {
        header_row: header_row,
        row_labels: table_rows.keys,
        first_column: 'B',
        last_column: columns.keys.last,
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      columns.each do |col, columns_clause|
        table_rows.values.each do |row, row_clause|
          cell = "#{col}#{row}"
          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(universe_clause).
            where(columns_clause).
            where(row_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
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
          dob_quality: source_client.DOBDataQuality,
          household_type: @household_types[last_service_history_enrollment.household_id],
          gender: source_client.gender,
        )
      end
    end
  end
end
