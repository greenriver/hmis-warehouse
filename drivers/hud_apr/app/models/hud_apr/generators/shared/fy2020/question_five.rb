###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFive < Base
    QUESTION_NUMBER = 'Question 5'.freeze

    TABLE_HEADER = [].freeze
    ROW_LABELS = [
      'Total number of persons served',
      'Number of adults (age 18 or over)',
      'Number of children (under age 18)',
      'Number of persons with unknown age',
      'Number of leavers',
      'Number of adult leavers',
      'Number of adult and head of household leavers',
      'Number of stayers',
      'Number of adult stayers',
      'Number of veterans',
      'Number of chronically homeless persons',
      'Number of youth under age 25',
      'Number of parenting youth under age 25 with children',
      'Number of adult heads of household',
      'Number of child and unknown-age heads of household',
      'Heads of households and adult stayers in the project 365 days or more',
    ].freeze
  end
end
