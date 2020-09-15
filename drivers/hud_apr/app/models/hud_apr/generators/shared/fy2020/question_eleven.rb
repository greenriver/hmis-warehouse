###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionEleven < Base
    QUESTION_NUMBER = 'Q11'.freeze
    QUESTION_TABLE_NUMBER = 'Q11'.freeze

    TABLE_HEADER = [
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
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])

      # cell_columns = ('A'..'N').to_a
      # project_rows.each_with_index do |row, row_index|
      #   row.each_with_index do |value, column_index|
      #     cell_name = cell_columns[column_index] + (row_index + 2).to_s
      #     @report.answer(question: QUESTION_TABLE_NUMBER, cell: cell_name).update(summary: value)
      #   end
      # end

      # metadata = {
      #   header_row: TABLE_HEADER,
      #   row_labels: [],
      #   first_column: 'A',
      #   last_column: 'N',
      #   first_row: 2,
      #   last_row: project_rows.size + 1,
      # }
      # @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      # @report.complete(QUESTION_NUMBER)
    end

    private def universe
      @universe ||= build_universe(QUESTION_NUMBER) do |_, enrollments|
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
