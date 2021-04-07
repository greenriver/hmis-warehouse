###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentySix < Base
    QUESTION_NUMBER = 'Question 26'.freeze

    private def q26a_chronic_households
      table_name = 'Q26a'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: ch_categories.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new
        ch_categories.values.each_with_index do |ch_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          household_ids = universe.members.where(population_clause).
            where(ch_clause).
            distinct.pluck(a_t[:household_id])
          # ignore previously counted households
          household_ids -= households.to_a
          members = universe.members.where(hoh_clause).where(a_t[:household_id].in(household_ids))

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26b_chronic_people
      table_name = 'Q26b'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: ch_categories.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        ch_categories.values.each_with_index do |ch_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(ch_clause)

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26c_ch_gender
      table_name = 'Q26c'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: q26c_responses.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        q26c_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:chronically_homeless].eq(true)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26d_ch_age
      table_name = 'Q26d'
      metadata = {
        header_row: [' '] + q26_populations.keys,
        row_labels: ch_age_ranges.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 11,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26_populations.values.each_with_index do |population_clause, col_index|
        ch_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_26d.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:chronically_homeless].eq(true)).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26e_health_conditions
      table_name = 'Q26e'
      metadata = {
        header_row: [' '] + q26e_populations.keys,
        row_labels: disability_clauses(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 9,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26e_populations.values.each_with_index do |suffix, col_index|
        disability_clauses(suffix).values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:chronically_homeless].eq(true)).
            where(response_clause)
          case suffix
          when :exit
            members = members.where(stayers_clause)
          when :latest
            members = members.where(leavers_clause)
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26f_income
      table_name = 'Q26f'
      metadata = {
        header_row: ['Number of Chronically Homeless Persons By Income Category'] + q26f_populations.keys,
        row_labels: ch_income_types(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26f_populations.values.each_with_index do |suffix, col_index|
        ch_income_types(suffix).values.each_with_index do |income_case, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_26f.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          adults = universe.members.where(a_t[:chronically_homeless].eq(true))
          adults = adults.where(stayers_clause) if suffix == :annual_assessment
          adults = adults.where(leavers_clause) if suffix == :exit

          ids = Set.new
          if income_case.is_a?(Symbol)
            adults.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case income_case
              when :earned
                ids << member.id if earned_income?(apr_client, suffix) && ! other_income?(apr_client, suffix)
              when :other
                ids << member.id if other_income?(apr_client, suffix) && ! earned_income?(apr_client, suffix)
              when :both
                ids << member.id if both_income_types?(apr_client, suffix)
              when :none
                ids << member.id if no_income?(apr_client, suffix)
              end
            end
            members = adults.where(id: ids)
          else
            members = adults.where(income_case)
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26g_income_sources
      table_name = 'Q26g'
      metadata = {
        header_row: [' '] + q26g_populations.keys,
        row_labels: ch_income_sources(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q26g_populations.values.each_with_index do |suffix, col_index|
        ch_income_sources(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank_26g.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(a_t[:chronically_homeless].eq(true))

          answer.update(summary: 0) and next if members.count.zero?

          if income_clause.is_a?(Hash)
            members = members.where.contains(income_clause)
          else
            # The final question doesn't require accessing the jsonb column
            members = members.where(income_clause)
          end
          members = members.where(stayers_clause) if suffix == :annual_assessment
          members = members.where(leavers_clause) if suffix == :exit

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26h_non_cash_benefits
      table_name = 'Q26h'
      metadata = {
        header_row: [' '] + q26h_populations.keys,
        row_labels: non_cash_benefit_types(:entry).keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a

      q26h_populations.values.each_with_index do |suffix, col_index|
        non_cash_benefit_types(suffix).values.each_with_index do |income_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(a_t[:chronically_homeless].eq(true))
          case suffix
          when :annual_assessment
            members = members.where(stayers_clause).
              where(a_t[:annual_assessment_expected].eq(true))
          when :exit
            # non-HoH clients are limited to those who exited on or after the HoH
            # For leavers, report only heads of households who left plus other adult household members who left at the same time as the head of household. Do not include household members who left prior to the head of household even though that person is otherwise considered a “leaver” in other report questions.
            additional_leaver_ids = Set.new
            members.where(leavers_clause).where(a_t[:head_of_household].eq(false)).
              pluck(a_t[:id], a_t[:head_of_household_id], a_t[:last_date_in_program]).each do |id, hoh_id, exit_date|
                hoh_exit_date = hoh_exit_dates[hoh_id]
                additional_leaver_ids << id if exit_date.blank? || hoh_exit_date.blank? || exit_date >= hoh_exit_date
              end
            members = members.where(leavers_clause).where(hoh_clause.or(a_t[:id].in(additional_leaver_ids)))
          end

          answer.update(summary: 0) and next if members.count.zero?

          members = members.where.contains(income_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q26_populations
      sub_populations
    end

    private def ch_categories
      {
        'Chronically Homeless' => a_t[:chronically_homeless].eq(true),
        'Not Chronically Homeless' => a_t[:chronically_homeless].eq(false),
        'Client Doesn’t Know/Client Refused' => a_t[:prior_living_situation].in([8, 9]),
        'Data Not Collected' => a_t[:prior_living_situation].eq(99),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q26c_responses
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

    private def ch_age_ranges
      {
        '0 - 17' => a_t[:age].between(0..17).and(a_t[:dob_quality].in([1, 2])),
      }.merge(age_ranges.except('Under 5', '5-12', '13-17'))
    end

    private def ch_income_types(suffix)
      income_responses(suffix).transform_keys do |k|
        k.sub('Adults', 'Chronically Homeless Persons').sub('adult stayers', 'Chronically Homeless Persons')
      end.except('1 or more source of income', 'Adults with Income Information at Start and Annual Assessment/Exit')
    end

    private def ch_income_sources(suffix)
      income_types(suffix).transform_keys do |k|
        k.sub('Adults', 'Chronically Homeless Persons')
      end
    end

    private def q26e_populations
      {
        'Conditions At Start' => :entry,
        'Conditions at Latest Assessment for Stayers' => :latest,
        'Conditions at Exit for Leavers' => :exit,
      }
    end

    private def q26f_populations
      {
        'Number of Chronically Homeless Persons at Start' => :start,
        'Number of Chronically Homeless Persons at Annual Assessment (Stayers)' => :annual_assessment,
        'Number of Chronically Homeless Persons at Exit (Leavers)' => :exit,
      }
    end

    private def q26g_populations
      {
        'Income at Start' => :start,
        'Income at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Income at Exit for Leavers' => :exit,
      }
    end

    private def q26h_populations
      {
        'Benefit at Start' => :start,
        'Benefit at Latest Annual Assessment for Stayers' => :annual_assessment,
        'Benefit at Exit for Leavers' => :exit,
      }
    end

    private def q26i_destinations
      destination_clauses
    end

    private def q26i_populations
      sub_populations
    end

    private def intentionally_blank
      [].freeze
    end

    private def intentionally_blank_26d
      [
        'C2',
        'E3',
        'E3',
        'E4',
        'E5',
        'E6',
        'E7',
        'E8',
        'E9',
        'E10',
      ].freeze
    end

    private def intentionally_blank_26f
      [
        'B8',
        'B9',
        'D8',
        'D9',
      ].freeze
    end

    private def intentionally_blank_26g
      [
        'B17',
      ].freeze
    end
  end
end
