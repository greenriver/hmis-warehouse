###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class QuestionFour < HudApr::Generators::Shared::Fy2020::QuestionFour
    QUESTION_NUMBER = 'Question 4'.freeze
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    TABLE_HEADER = [
      'Organization Name',
      'Organization ID',
      'Project Name',
      'Project ID',
      'HMIS Project Type',
      'Method for Tracking ES',
      'Affiliated with a residential project',
      'Project IDs of affiliations',
      'CoC Number',
      'Geocode',
      'Victim Service Provider',
      'HMIS Software Name',
      'Report Start Date',
      'Report End Date',
    ].freeze

    HMIS_SOFTWARE_NAME = 'OpenPath HMIS Warehouse'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end
  end
end
