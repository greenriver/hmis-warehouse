###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionThirteen < Base
    QUESTION_NUMBER = 'Question 13'.freeze

    def self.table_descriptions
      {
        'Question 13' => 'Physical and Mental Health Conditions',
        'Q13a1' => 'Physical and Mental Health Conditions at Start',
        'Q13b1' => 'Physical and Mental Health Conditions at Exit',
        'Q13c1' => 'Physical and Mental Health Conditions for Stayers',
        'Q13a2' => 'Number of Conditions at Start',
        'Q13b2' => 'Number of Conditions at Exit',
        'Q13c2' => 'Number of Conditions for Stayers',
      }.freeze
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
          extra_limit: disability_at_exit_clause,
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
          extra_limit: disability_at_exit_clause,
        },
        {
          table_name: 'Q13c2',
          suffix: :latest,
          extra_limit: stayers_clause,
        },
      ]
    end

    private def disability_at_exit_clause
      # According to the spec, everyone, including children should have this
      # exit assessment, if they don't they should get counted in 'Data Not Collected'
      leavers_clause
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
        adjusted_sub_populations.values.each_with_index do |population_clause, col_index|
          disability_clauses(suffix).values.each_with_index do |disability_clause, row_index|
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
        adjusted_sub_populations.values.each_with_index do |population_clause, col_index|
          disability_count_clauses.values.each_with_index do |method, row_index|
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
  end
end
