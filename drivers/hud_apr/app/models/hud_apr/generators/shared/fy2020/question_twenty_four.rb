###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyFour < Base
    QUESTION_NUMBER = 'Question 24'.freeze
    QUESTION_TABLE_NUMBERS = ['Q24'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q24_destination
      table_name = 'Q24'
      metadata = {
        header_row: [' '] + q24_populations.keys,
        row_labels: q24_assessment.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 16,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q24_populations.values.each_with_index do |population_clause, col_index|
        q24_assessment.values.each_with_index do |assessment_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(assessment_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q24_populations
      @q24_populations ||= sub_populations
    end

    private def q24_assessment
      {
        'Able to maintain the housing they had at project start-- Without a subsidy' => a_t[:housing_assessment].eq(1).
          and(a_t[:subsidy_information].eq(1)),
        'Able to maintain the housing they had at project start--With the subsidy they had at project start' => a_t[:housing_assessment].eq(1).
          and(a_t[:subsidy_information].eq(2)),
        'Able to maintain the housing they had at project start--With an on-going subsidy acquired since project start' => a_t[:housing_assessment].eq(1).
          and(a_t[:subsidy_information].eq(3)),
        'Able to maintain the housing they had at project start--Only with financial assistance other than a subsidy' => a_t[:housing_assessment].eq(1).
          and(a_t[:subsidy_information].eq(4)),
        'Moved to new housing unit--With on-going subsidy' => a_t[:housing_assessment].eq(2).
          and(a_t[:subsidy_information].eq(3)),
        'Moved to new housing unit--Without an on-going subsidy' => a_t[:housing_assessment].eq(2).
          and(a_t[:subsidy_information].eq(1)),
        'Moved in with family/friends on a temporary basis' => a_t[:housing_assessment].eq(3),
        'Moved in with family/friends on a permanent basis' => a_t[:housing_assessment].eq(4),
        'Moved to a transitional or temporary housing facility or program' => a_t[:housing_assessment].eq(5),
        'Client became homeless – moving to a shelter or other place unfit for human habitation' => a_t[:housing_assessment].eq(6),
        'Client went to jail/prison' => a_t[:housing_assessment].eq(7),
        'Client died' => a_t[:housing_assessment].eq(10),
        'Client doesn’t know/Client refused' => a_t[:housing_assessment].in([8, 9]),
        'Data not collected (no exit interview completed)' => a_t[:housing_assessment].eq(99),
        'Total' => leavers_clause,
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
          housing_assessment: last_service_history_enrollment.enrollment.exit&.HousingAssessment,
          subsidy_information: last_service_history_enrollment.enrollment.exit&.SubsidyInformation,
        )
      end
    end
  end
end
