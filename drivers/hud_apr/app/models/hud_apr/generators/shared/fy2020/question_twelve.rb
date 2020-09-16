###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwelve < Base
    QUESTION_NUMBER = 'Question 12'.freeze
    QUESTION_TABLE_NUMBERS = ['Q12a', 'Q12b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q12a_race
      q12b_ethnicity

      @report.complete(QUESTION_NUMBER)
    end

    private def q12a_race
      table_name = 'Q12a'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: races.map { |_, m| m[:label] },
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        races.each_with_index do |(_, race), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(population_clause).
            where(race[:clause])
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q12b_ethnicity
      table_name = 'Q12b'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: ethnicities.map { |_, m| m[:label] },
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        ethnicities.each_with_index do |(_, ethnicity), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(population_clause).
            where(ethnicity[:clause])
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
        source_client = last_service_history_enrollment.source_client

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          race: calculate_race(source_client),
          ethnicity: source_client.Ethnicity,
          household_type: @household_types[last_service_history_enrollment.household_id],
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
