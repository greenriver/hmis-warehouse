###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEleven < Base
    QUESTION_NUMBER = 'Question 11'.freeze
    QUESTION_TABLE_NUMBER = 'Q11'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q11_ages
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: age_ranges.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 13,
      }
      @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        age_ranges.to_a.each_with_index do |(_, age_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: cell)
          members = universe.members.
            where(population_clause).
            where(age_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def intentionally_blank
      [
        'C2',
        'C3',
        'C4',
        'E5',
        'E6',
        'E7',
        'E8',
        'E9',
        'E10',
      ].freeze
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
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
