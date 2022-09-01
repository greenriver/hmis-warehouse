###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionTwentyFour < Base
    QUESTION_NUMBER = 'Question 24'.freeze

    def self.table_descriptions
      {
        'Question 24' => 'Homelessness Prevention Housing Assessment at Exit',
      }.freeze
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
        'Client went to jail/prison' => a_t[:housing_assessment].eq(7),
        'Client died' => a_t[:housing_assessment].eq(10),
        'Client doesn\'t know/Client refused' => a_t[:housing_assessment].in([8, 9]),
        'Data not collected (no exit interview completed)' => a_t[:housing_assessment].eq(99).or(leavers_clause.and(a_t[:housing_assessment].eq(nil))),
        'Total' => leavers_clause,
      }.freeze
    end

    private def intentionally_blank
      [].freeze
    end
  end
end
