###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyThree < Base
    QUESTION_NUMBER = 'Question 23'.freeze
    QUESTION_TABLE_NUMBERS = ['Q23c'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q23c_destination
      table_name = 'Q23c'
      metadata = {
        header_row: [' '] + q23c_populations.keys,
        row_labels: q23c_destinations_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q23c_populations.values.each_with_index do |population_clause, col_index|
        q23c_destinations.values.each_with_index do |destination_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          value = 0

          if destination_clause.is_a?(Symbol)
            case destination_clause
            when :percentage
              members = universe.members.where(population_clause)
              positive = members.where(q23c_destinations['Total persons exiting to positive housing destinations']).count
              total = members.count
              excluded = members.where(q23c_destinations['Total persons whose destinations excluded them from the calculation']).count
              value = (positive.to_f / (total - excluded) * 100).round(4) if total.positive? && excluded != total
            end
          else
            members = universe.members.where(population_clause).where(destination_clause)
            value = members.count
          end
          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q23c_destinations_headers
      q23c_destinations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def q23c_populations
      @q23c_populations ||= sub_populations
    end

    private def q23c_destinations
      destination_clauses
    end

    private def intentionally_blank
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B17',
        'C17',
        'D17',
        'E17',
        'F17',
        'B28',
        'C28',
        'D28',
        'E28',
        'F28',
        'B36',
        'C36',
        'D36',
        'E36',
        'F36',
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
          destination: last_service_history_enrollment.destination,
        )
      end
    end
  end
end
