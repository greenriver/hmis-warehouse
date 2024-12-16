###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
        # https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recT9z9YkbQtWwAmm
        # "Report each household by type as described in Determining Each Client’s Household Type and Counting Distinct Households,"
        # which section in turn refers the user to "Unduplicated Household Counts by Individual Attribute" in the HMIS Reporting Glossary.
        # The instructions in that section of the Reporting Glossary read "Unduplicated household counts should be determined by
        # performing a distinct count of [personal IDs] of all heads of households (people who have [relationship to head of household] = Self)
        # in the report range." All household counts in the APR rely on counts of heads of household rather than counts of Household ID.
        q25b_responses.values.each_with_index do |response_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          # limit members only to heads of households. If there is a data issue where ther are more than one HoH for the household,
          # we want both heads of the household to be included.
          members = universe.members.where(hoh_clause.and(a_t[:household_type].not_eq('children_only'))).
            where.not(a_t[:age].eq(nil).and(a_t[:household_type].eq('unknown'))). # Special case from Datalab test?
            where(population_clause)

          ids = Set.new
          if response_clause.is_a?(Symbol)
            members.preload(:universe_membership).find_each do |member|
              apr_client = member.universe_membership
              case response_clause
              when :chronic
                ids << member.id if household_veterans_chronically_homeless?(apr_client)
              when :not_chronic
                ids << member.id if household_veterans_non_chronically_homeless?(apr_client)
              when :veteran # NOTE: actually not-a-veteran
                ids << member.id if all_household_adults_non_veterans?(apr_client)
              when :refused
                ids << member.id if household_adults_refused_veterans(apr_client).any?
              when :not_collected
                ids << member.id if household_adults_missing_veterans(apr_client).any?
              end
            end
            members = members.where(id: ids)
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
      sub_populations_by_destination_question(question: 'Q25i', members: universe.members.where(veteran_clause))
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
