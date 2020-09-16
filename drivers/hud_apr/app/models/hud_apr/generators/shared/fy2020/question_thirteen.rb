###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionThirteen < Base
    QUESTION_NUMBER = 'Question 13'.freeze
    QUESTION_TABLE_NUMBERS = [
      'Q13a1',
      'Q13b1',
      'Q13c1',
      'Q13a2',
      'Q13b2',
      'Q13c2',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q13x1_conditions
      q13x2_condition_counts

      @report.complete(QUESTION_NUMBER)
    end

    private def disability_stages
      [
        {
          table_name: 'Q13a1',
          suffix: :entry,
        },
        {
          table_name: 'Q13b1',
          suffix: :exit,
        },
        {
          table_name: 'Q13c1',
          suffix: :latest,
          extra_limit: stayers_clause,
        },
      ]
    end

    private def disability_count_stages
      [
        {
          table_name: 'Q13a2',
          suffix: :entry,
        },
        {
          table_name: 'Q13b2',
          suffix: :exit,
        },
        {
          table_name: 'Q13c2',
          suffix: :latest,
          extra_limit: stayers_clause,
        },
      ]
    end

    private def adjusted_sub_populations
      @adjusted_sub_populations ||= {}.tap do |pops|
        pops['Total Persons'] = sub_populations['Total']
        pops['Without Children'] = sub_populations['Without Children']
        pops['Adults in HH with Children & Adults'] = sub_populations['With Children and Adults'].and(adult_clause)
        pops['Children in HH with Children & Adults'] = sub_populations['With Children and Adults'].and(child_clause)
        pops['With Only Children'] = sub_populations['With Only Children']
        pops['Unknown Household Type'] = sub_populations['Unknown Household Type']
      end
    end

    private def disability_clauses(suffix)
      {
        'Mental Health Problem' => a_t["mental_health_problem_#{suffix}".to_sym].eq(1),
        'Alcohol Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true),
        'Drug Abuse' => a_t["drug_abuse_#{suffix}".to_sym].eq(true),
        'Both Alcohol and Drug Abuse' => a_t["alcohol_abuse_#{suffix}".to_sym].eq(true).
          and(a_t["drug_abuse_#{suffix}".to_sym].eq(true)),
        'Chronic Health Condition' => a_t["chronic_disability_#{suffix}".to_sym].eq(1),
        'HIV/AIDS' => a_t["hiv_aids_#{suffix}".to_sym].eq(1),
        'Developmental Disability' => a_t["developmental_disability_#{suffix}".to_sym].eq(1),
        'Physical Disability' => a_t["physical_disability_#{suffix}".to_sym].eq(1),
      }
    end

    private def disability_count_clauses
      {
        'None' => :none,
        '1 Condition' => :one,
        '2 Conditions' => :two,
        '3+ Conditions' => :three,
        'Condition Unknown' => :unknown,
        'Client Doesn’t Know/Client Refused' => :refused,
        'Data Not Collected' => :not_collected,
        'Total' => :total,
      }
    end

    private def q13x1_conditions
      disability_stages.each do |stage|
        table_name = stage[:table_name]
        suffix = stage[:suffix]

        metadata = {
          header_row: [' '] + adjusted_sub_populations.keys,
          row_labels: disability_clauses(suffix).keys,
          first_column: 'B',
          last_column: 'G',
          first_row: 2,
          last_row: 9,
        }
        @report.answer(question: table_name).update(metadata: metadata)

        cols = (metadata[:first_column]..metadata[:last_column]).to_a
        rows = (metadata[:first_row]..metadata[:last_row]).to_a
        adjusted_sub_populations.each_with_index do |(_, population_clause), col_index|
          disability_clauses(suffix).each_with_index do |(_, disability_clause), row_index|
            cell = "#{cols[col_index]}#{rows[row_index]}"

            answer = @report.answer(question: table_name, cell: cell)
            members = universe.members.
              where(population_clause).
              where(disability_clause)
            members = members.where(stage[:extra_limit]) if stage[:extra_limit].present?
            answer.add_members(members)
            answer.update(summary: members.count)
          end
        end
      end
    end

    private def q13x2_condition_counts
      disability_count_stages.each do |stage|
        table_name = stage[:table_name]
        suffix = stage[:suffix]

        metadata = {
          header_row: [' '] + adjusted_sub_populations.keys,
          row_labels: disability_count_clauses.keys,
          first_column: 'B',
          last_column: 'G',
          first_row: 2,
          last_row: 9,
        }
        @report.answer(question: table_name).update(metadata: metadata)

        cols = (metadata[:first_column]..metadata[:last_column]).to_a
        rows = (metadata[:first_row]..metadata[:last_row]).to_a
        adjusted_sub_populations.each_with_index do |(_, population_clause), col_index|
          disability_count_clauses.each_with_index do |(_, method), row_index|
            cell = "#{cols[col_index]}#{rows[row_index]}"

            answer = @report.answer(question: table_name, cell: cell)
            pop_members = universe.members.where(population_clause)
            pop_members = pop_members.where(stage[:extra_limit]) if stage[:extra_limit].present?
            ids = Set.new
            pop_members.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              disability_truths = [
                apr_client["mental_health_problem_#{suffix}".to_sym] == 1,
                apr_client["alcohol_abuse_#{suffix}".to_sym],
                apr_client["drug_abuse_#{suffix}".to_sym],
                apr_client["chronic_disability_#{suffix}".to_sym] == 1,
                apr_client["hiv_aids_#{suffix}".to_sym] == 1,
                apr_client["developmental_disability_#{suffix}".to_sym] == 1,
                apr_client["physical_disability_#{suffix}".to_sym] == 1,
              ]
              case method
              when :none
                ids << member.id if disability_truths.none?(true) && apr_client.disabling_condition.zero?
              when :unknown
                ids << member.id if disability_truths.none?(true) && apr_client.disabling_condition == 1
              when :refused
                ids << member.id if disability_truths.none?(true) && apr_client.disabling_condition.in?([8, 9])
              when :not_collected
                ids << member.id if disability_truths.none?(true) && apr_client.disabling_condition.in?([99, nil])
              when :one
                ids << member.id if disability_truths.count(true) == 1
              when :two
                ids << member.id if disability_truths.count(true) == 2
              when :three
                ids << member.id if disability_truths.count(true) > 2
              when :total
                ids << member.id
              end
            end
            members = pop_members.where(id: ids)
            answer.add_members(members)
            answer.update(summary: members.count)
          end
        end
      end
    end

    private def universe # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
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

      @universe ||= build_universe(QUESTION_NUMBER, before_block: batch_initializer) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        disabilities_at_entry = enrollment.disabilities.select { |d| d.DataCollectionStage == 1 }
        disabilities_at_exit = enrollment.disabilities.select { |d| d.DataCollectionStage == 3 }
        max_disability_date = enrollment.disabilities.select { |d| d.InformationDate <= @report.end_date }.
          map(&:InformationDate).max
        disabilities_latest = enrollment.disabilities.select { |d| d.InformationDate == max_disability_date }

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          disabling_condition: enrollment.DisablingCondition,
          developmental_disability_entry: disabilities_at_entry.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_entry: disabilities_at_entry.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_entry: disabilities_at_entry.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_entry: disabilities_at_entry.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_entry: disabilities_at_entry.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_entry: disabilities_at_entry.detect(&:substance?)&.DisabilityResponse == 2,
          developmental_disability_exit: disabilities_at_exit.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_exit: disabilities_at_exit.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_exit: disabilities_at_exit.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_exit: disabilities_at_exit.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_exit: disabilities_at_exit.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_exit: disabilities_at_exit.detect(&:substance?)&.DisabilityResponse == 2,
          developmental_disability_latest: disabilities_latest.detect(&:developmental?)&.DisabilityResponse,
          hiv_aids_latest: disabilities_latest.detect(&:hiv?)&.DisabilityResponse,
          physical_disability_latest: disabilities_latest.detect(&:physical?)&.DisabilityResponse,
          chronic_disability_latest: disabilities_latest.detect(&:chronic?)&.DisabilityResponse,
          mental_health_problem_latest: disabilities_latest.detect(&:mental?)&.DisabilityResponse,
          substance_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse,
          alcohol_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse == 1,
          drug_abuse_latest: disabilities_latest.detect(&:substance?)&.DisabilityResponse == 2,

          household_type: @household_types[last_service_history_enrollment.household_id],
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
