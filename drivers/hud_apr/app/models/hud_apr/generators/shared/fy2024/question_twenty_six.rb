###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentySix < Base
    QUESTION_NUMBER = 'Question 26'.freeze

    def self.table_descriptions
      {
        'Question 26' => 'Chronic Homeless Questions',
        'Q26a' => 'Chronic Homeless Status - Number of Households w/at least one or more CH person',
        'Q26b' => 'Number of Chronically Homeless Persons by Household',
        'Q26c' => 'Gender of Chronically Homeless Persons',
        'Q26d' => 'Age of Chronically Homeless Persons',
        'Q26e' => 'Physical and Mental Health Conditions - Chronically Homeless Persons',
        'Q26f' => 'Client Cash Income - Chronically Homeless Persons',
        'Q26g' => 'Type of Cash Income Sources - Chronically Homeless Persons',
        'Q26h' => 'Type of Non-Cash Benefit Sources - Chronically Homeless Persons',
      }.freeze
    end

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
      relevant_clients = universe.members.where(a_t[:project_type].in([0, 1, 2, 3, 4, 6, 8, 9, 10, 11, 12, 13, 14]))
      q26_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new
        ch_categories.values.each_with_index do |ch_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          household_ids = relevant_clients.where(population_clause).
            where(ch_clause).
            distinct.pluck(a_t[:household_id])
          # ignore previously counted households, except for the last line (total)
          if row_index < ch_categories.size - 1
            household_ids -= households.to_a
            households += household_ids
          end
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
      members = universe.members.where(a_t[:chronically_homeless].eq(true))
      question_sheet(question: 'Q26c') do  |sheet|
        q26_populations.keys.each do |label|
          sheet.add_header(label: label)
        end

        gender_identities.each_pair do |label, gender_cond|
          gender_scope = members.where(gender_cond[1])
          sheet.append_row(label: label) do |row|
            q26_populations.values.each do |pop_cond|
              row.append_cell_members(members: gender_scope.where(pop_cond))
            end
          end
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
            members = members.where(leavers_clause)
          when :latest
            members = members.where(stayers_clause)
          end

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
        'Chronically Homeless' => a_t[:chronically_homeless_detail].eq('yes'),
        'Not Chronically Homeless' => a_t[:chronically_homeless_detail].eq('no'),
        label_for(:dkptr) => a_t[:chronically_homeless_detail].eq('dk_or_r'),
        label_for(:data_not_collected) => a_t[:chronically_homeless_detail].eq('missing'),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q26c_responses
      {
        'Male' => a_t[:gender_multi].eq('1'),
        'Female' => a_t[:gender_multi].eq('0'),
        'No Single Gender' => a_t[:gender_multi].in(::HudUtility2024.no_single_gender_queries),
        'Questioning' => a_t[:gender_multi].in(::HudUtility2024.questioning_gender_queries),
        'Transgender' => a_t[:gender_multi].in(::HudUtility2024.transgender_gender_queries),
        label_for(:dkptr) => a_t[:gender_multi].in(['8', '9']),
        'Data Not Collected' => a_t[:gender_multi].eq('99'),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def ch_age_ranges
      {
        '0 - 17' => a_t[:age].between(0..17).and(a_t[:dob_quality].in([1, 2])),
      }.merge(apr_age_ranges.except('Under 5', '5-12', '13-17'))
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
  end
end
