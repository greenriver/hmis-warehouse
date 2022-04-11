###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionTwentySix < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q26: Demographics'.freeze
    QUESTION_TABLE_NUMBER = 'Q26'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    EMPTY_CELL = ' '.freeze

    TABLE_HEADER = [
      EMPTY_CELL,
      EMPTY_CELL,
      'Of those with an active, enrolled PATH status during this reporting period, how many individuals are in each of the following categories?',
    ].freeze

    def sections
      {
        '26a. Gender' => genders,
        '26b. Age' => age_ranges,
        '26c. Race (Note: An individual who identifies as multiracial should be counted in all applicable categories. This demographic element will not sum to total persons enrolled)' => races,
        '26d. Ethnicity' => ethnicities,
        '26e. Veteran Status (adults only)' => veteran_statuses,
        '26f. Co-occurring disorder' => substance_use_disorders,
        '26g. SOAR connection' => soar_connections,
        '26h. Prior Living Situation' => prior_living_situations,
        '26i. Length of stay in prior living situation (emergency shelter or place not meant for human habitation only)' => length_of_stays,
        '26j. Chronically homeless (at project start)' => chronically_homeless_statuses,
        '26k. Domestic Violence History (adults only)' => domestic_violence_statuses,
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
