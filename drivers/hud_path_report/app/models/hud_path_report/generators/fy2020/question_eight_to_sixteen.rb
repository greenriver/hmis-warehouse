###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionEightToSixteen < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q8-Q16'.freeze
    QUESTION_TABLE_NUMBER = 'Q8-Q16'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Persons served during this reporting period:',
      'Count',
    ].freeze

    ROW_LABELS = [
      '8. Number of persons contacted by PATH-funded staff this reporting period',
      '9. Number of new persons contacted this reporting period in a PATH Street Outreach project',
      '10. Number of new persons contacted this reporting period in a PATH Services Only project',
      '11. Total number of new persons contacted this reporting period (#9 + #10 = total new clients contacted)',
      '12a. Instances of contact this reporting period prior to date of enrollment',
      '12b. Total instances of contact during the reporting period',
      '13a. Number of new persons contacted this reporting period who could not be enrolled because of ineligibility for PATH',
      '13b. Number of new persons contacted this reporting period who could not be enrolled because provider was unable to locate the client',
      '14. Number of new persons contacted this reporting period who became enrolled in PATH',
      '15. Number with active, enrolled PATH status at any point during the reporting period',
      '16. Number of active, enrolled PATH clients receiving community mental health services through any funding source at any point during the reporting period',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
