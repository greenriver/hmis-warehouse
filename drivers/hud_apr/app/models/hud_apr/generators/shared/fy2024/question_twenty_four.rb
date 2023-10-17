###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentyFour < Base
    QUESTION_NUMBER = 'Question 24'.freeze

    def self.table_descriptions
      {
        'Question 24' => '',
        'Question 24a' => 'Homelessness Prevention Housing Assessment at Exit',
        'Question 24b' => 'Moving On Assistance Provided to Households in PSH',
        'Question 24c' => 'Sexual Orientation of Adults in PSH',
        'Question 24d' => 'Language of Persons Requiring Translation Assistance',
      }.freeze
    end

    def q24a_homelessness_prevention_housing_assessment_at_exit
      table_name = 'Q24a'
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

          members = universe.members.
            where(population_clause).
            where(assessment_clause).
            where(a_t[:project_type].eq(12)) # Only prevention project enrollments are counted
          value = members.count

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    def q24b_moving_on_assistance_provided_to_households_in_psh
      raise 'tbd'
    end

    def q24c_sexual_orientation_of_adults_in_psh_in_psh
      raise 'tbd'
    end

    def q24d_language_of_persons_requiring_translation_assistance
      relevant_members = universe.members.where(a_t[:translation_needed].eq(true)).
        where(a_t[:preferred_language].not_eq(nil).or(a_t[:preferred_language_different].not_eq(nil)))

      different_language_members = []
      language_rows = []
      relevant_members.group_by(&:preferred_language).each_pair do |code, members|
        if code
          language_rows << [code.to_i, members]
        else
          different_language_members = members
        end
      end
      # top 20 sorted by count with code as tie breaker
      language_rows = language_rows.sort_by { |code, members| [members.size, code] }.take(20)

      question_sheet(question: 'Q24d') do |sheet|
        sheet.add_header(col: 'A', label: 'Language Response (Top 20 Languages Selected')
        sheet.add_header(col: 'B', label: 'Total Persons Requiring Translation Assistance')

        language_rows.each do |code, members|
          label = HudUtility2024.preferred_languages.fetch(code.to_i)
          sheet.append_row(label: label) do |row|
            row.append_cell_members(members: members)
          end
        end
        sheet.append_row(label: 'Different Preferred Language') do |row|
          row.append_cell_members(members: different_language_members)
        end
        sheet.append_row(label: 'Total') do |row|
          row.append_cell_members(members: relevant_members)
        end
      end
    end

    private def q24_populations
      sub_populations
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
        'Client became homeless - moving to a shelter or other place unfit for human habitation' => a_t[:housing_assessment].eq(6),
        'Jail/prison' => a_t[:housing_assessment].eq(7),
        'Deceased' => a_t[:housing_assessment].eq(10),
        label_for(:dkptr) => a_t[:housing_assessment].in([8, 9]),
        'Data not collected (no exit interview completed)' => a_t[:housing_assessment].eq(99).or(leavers_clause.and(a_t[:housing_assessment].eq(nil))),
        'Total' => leavers_clause,
      }.freeze
    end

    private def intentionally_blank
      [].freeze
    end
  end
end
