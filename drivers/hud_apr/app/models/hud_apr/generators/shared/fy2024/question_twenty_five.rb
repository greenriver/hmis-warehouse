###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentyFive < Base
    include HudReports::SubPopulationsBySubsidyTypeQuestion
    include HudReports::SubPopulationsByDestinationQuestion
    include HudReports::GenderQuestion

    QUESTION_NUMBER = 'Question 25'.freeze

    def self.table_descriptions
      {
        'Question 25' => 'Veterans Questions',
        'Q25a' => 'Number of Veterans',
        'Q25b' => 'Number of Veteran Households',
        'Q25c' => 'Gender - Veterans',
        'Q25d' => 'Age - Veterans',
        'Q25i' => 'Exit Destination - Veterans',
        'Q25j' => 'Exit Destination – Subsidy Type of Persons Exiting to Rental by Client With An Ongoing Subsidy - Veteran',
      }.freeze
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
      q25_populations.values.each_with_index do |population_clause, col_index|
        q25a_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(adult_clause).where(population_clause).where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25b_number_of_households
      # NOTE: CH Status == prior_living_situation in respect to 8, 9, 99

      table_name = 'Q25b'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: q25b_responses.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        households = Set.new # only count each household once
        q25b_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          members = universe.members.where(hoh_clause.and(a_t[:household_type].not_eq('children_only'))).
            where.not(a_t[:age].eq(nil).and(a_t[:household_type].eq('unknown'))). # Special case from Datalab test?
            where(population_clause)

          ids = Set.new
          if response_clause.is_a?(Symbol)
            # Count any households where any adult or HoH in the household
            members.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case response_clause
              when :chronic
                if ! households.include?(apr_client.household_id) && household_veterans_chronically_homeless?(apr_client)
                  ids << member.id
                  households << apr_client.household_id
                end
              when :not_chronic
                if ! households.include?(apr_client.household_id) && household_veterans_non_chronically_homeless?(apr_client)
                  ids << member.id
                  households << apr_client.household_id
                end
              when :veteran
                if ! households.include?(apr_client.household_id) && all_household_adults_non_veterans?(apr_client)
                  ids << member.id
                  households << apr_client.household_id
                end
              when :refused
                if ! households.include?(apr_client.household_id) && household_adults_refused_veterans(apr_client).any?
                  ids << member.id
                  households << apr_client.household_id
                end
              when :not_collected
                if ! households.include?(apr_client.household_id) && household_adults_missing_veterans(apr_client).any?
                  ids << member.id
                  households << apr_client.household_id
                end
              end
            end
            members = members.where(id: ids)
          else
            members = members.where(a_t[:household_id].in(households.to_a))
          end

          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25c_veteran_gender
      gender_question(
        question: 'Q25c',
        members: universe.members.where(veteran_clause),
        populations: q25_populations,
      )
    end

    private def q25d_veteran_age
      table_name = 'Q25d'
      metadata = {
        header_row: [' '] + q25_populations.keys,
        row_labels: veteran_age_ranges.keys,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: 10,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q25_populations.values.each_with_index do |population_clause, col_index|
        veteran_age_ranges.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(veteran_clause).
            where(population_clause).
            where(response_clause)
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q25i_destination
      sub_populations_by_destination_question(question: 'Q25i', members: universe.members.where(veteran_clause), last_column: 'E')
    end

    def q25j_exit_destination_subsidy
      sub_populations_by_subsidy_type_question(question: 'Q25j', members: universe.members.where(veteran_clause), sub_pops: q25_populations, last_column: 'E')
    end

    private def veteran_age_ranges
      apr_age_ranges.except('Under 5', '5-12', '13-17')
    end

    private def q25_populations
      sub_populations.except('With Only Children')
    end

    private def q25a_responses
      {
        'Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(true).and(veteran_clause),
        'Non-Chronically Homeless Veteran' => a_t[:chronically_homeless].eq(false).and(veteran_clause),
        'Not a Veteran' => a_t[:veteran_status].eq(0).or(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))),
        label_for(:dkptr) => a_t[:veteran_status].in([8, 9]),
        'Data Not Collected' => a_t[:veteran_status].eq(99),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q25b_responses
      {
        'Chronically Homeless Veteran' => :chronic,
        'Non-Chronically Homeless Veteran' => :not_chronic,
        'Not a Veteran' => :veteran,
        label_for(:dkptr) => :refused,
        'Data Not Collected' => :not_collected,
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def q25c_responses
      gender_identities
    end

    private def veteran_income_types(suffix)
      income_responses(suffix).transform_keys do |k|
        k.sub('Adults', 'Veterans').sub('adult stayers', 'veterans')
      end.except('1 or more source of income', 'Adults with Income Information at Start and Annual Assessment/Exit')
    end

    private def veteran_income_sources(suffix)
      income_types(suffix).transform_keys do |k|
        k.sub('Adults', 'Veterans')
      end
    end

    private def intentionally_blank
      [].freeze
    end
  end
end
