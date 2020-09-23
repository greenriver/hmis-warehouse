###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFive < Base
    QUESTION_NUMBER = 'Question 25'.freeze
    QUESTION_TABLE_NUMBERS = ['Q25a', 'Q25b', 'Q25c', 'Q25d', 'Q25e', 'Q25f', 'Q25g', 'Q25h', 'Q25i'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q25a_number_of_veterans
      table_name = 'Q25a'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25a_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.each_with_index do |(_, population_clause), col_index|
        q25a_responses.to_a.each_with_index do |(_, response_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25b_number_of_households
      # table_name = 'Q25b'
      # metadata = {
      #   header_row: [' '] + q25_populations.keys,
      #   row_labels: q25a_responses.keys,
      #   first_column: 'B',
      #   last_column: 'E',
      #   first_row: 2,
      #   last_row: 7,
      # }
      # @report.answer(question: table_name).update(metadata: metadata)

      # cols = (metadata[:first_column]..metadata[:last_column]).to_a
      # rows = (metadata[:first_row]..metadata[:last_row]).to_a
      # q25_populations.each_with_index do |(_, population_clause), col_index|
      #   q25a_responses.to_a.each_with_index do |(_, response_clause), row_index|
      #     cell = "#{cols[col_index]}#{rows[row_index]}"
      #     next if intentionally_blank.include?(cell)

      #     answer = @report.answer(question: table_name, cell: cell)

      #     members = universe.members.where(adult_or_hoh_clause).
      #       where(population_clause).
      #       where(response_clause)
      #     value = members.count

      #     answer.add_members(members)
      #     answer.update(summary: value)
      #   end
      # end
    end

    private def q25c_veteran_gender
      table_name = 'Q25c'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25c_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.each_with_index do |(_, population_clause), col_index|
        q25c_responses.to_a.each_with_index do |(_, response_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:veteran_status].eq(1)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25d_veteran_age
      table_name = 'Q25d'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: age_ranges.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.each_with_index do |(_, population_clause), col_index|
        age_ranges.to_a.each_with_index do |(_, response_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:veteran_status].eq(1)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25_populations
      @q25_populations ||= sub_populations.except('With Only Children')
    end

    private def q25a_responses
      {
        'Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(true).and(a_t[:veteran_status].eq(1)),
        'Non-Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(false).and(a_t[:veteran_status].eq(1)),
        'Not a Veteran' => a_t[:veteran_status].eq(0),
        "Client Doesn't Know/Client Refused" => a_t[:veteran_status].in([8, 9]),
        'Data Not Collected' => a_t[:veteran_status].eq(99),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q25c_responses
      {
        'Male' => a_t[:gender].eq(1),
        'Female' => a_t[:gender].eq(0),
        'Trans Female (MTF or Male to Female)' => a_t[:gender].eq(2),
        'Trans Male (FTM or Female to Male)' => a_t[:gender].eq(3),
        'Gender Non-Conforming (i.e. not exclusively male or female)' => a_t[:gender].eq(4),
        "Client Doesn't Know/Client Refused" => a_t[:gender].in([8, 9]),
        'Data Not Collected' => a_t[:gender].eq(99).or(a_t[:gender].eq(nil)),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def intentionally_blank
      [].freeze
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

      @universe ||= build_universe(
        QUESTION_NUMBER,
        before_block: batch_initializer,
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          household_type: @household_types[last_service_history_enrollment.household_id],
          project_type: last_service_history_enrollment.computed_project_type,
          veteran_status: source_client.VeteranStatus,
          chronically_homeless: enrollment.chronically_homeless_at_start?,
        )
      end
    end
  end
end
