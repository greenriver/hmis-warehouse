###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFourteen < Base
    QUESTION_NUMBER = 'Question 14'.freeze
    QUESTION_TABLE_NUMBERS = ['Q14a', 'Q14b'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q14a_dv_history
      table_name = 'Q14a'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        yes_know_dkn_clauses(a_t[:domestic_violence]).each_with_index do |(_, dv_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.
            where(adult_or_hoh_clause). # only valid for HoH and adults
            where(population_clause).
            where(dv_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q14b_dv_fleeing
      table_name = 'Q14b'
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: yes_know_dkn_clauses(a_t[:domestic_violence]).keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        yes_know_dkn_clauses(a_t[:domestic_violence]).each_with_index do |(_, dv_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.
            where(adult_or_hoh_clause). # only valid for HoH and adults
            where(a_t[:currently_fleeing].eq(1)). # Q14b requires currently fleeing
            where(population_clause).
            where(dv_clause)
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
          date = [
            @report.start_date,
            last_service_history_enrollment.first_date_in_program,
          ].max
          @household_types[hh_id] = household_makeup(hh_id, date)
        end
      end

      @universe ||= build_universe(QUESTION_NUMBER, preloads: { enrollment: :health_and_dvs }, before_block: batch_initializer) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client

        health_and_dv = enrollment.health_and_dvs.
          select { |h| h.InformationDate <= @report.end_date }.
          max_by(&:InformationDate)

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          head_of_household: last_service_history_enrollment[:head_of_household],
          domestic_violence: health_and_dv.DomesticViolenceVictim,
          currently_fleeing: health_and_dv.CurrentlyFleeing,
          household_type: @household_types[last_service_history_enrollment.household_id],
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
