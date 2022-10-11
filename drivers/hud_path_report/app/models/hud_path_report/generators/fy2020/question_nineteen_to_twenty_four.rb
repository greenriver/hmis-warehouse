###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionNineteenToTwentyFour < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q19-Q24: Outcomes'.freeze
    QUESTION_TABLE_NUMBER = 'Q19-Q24'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Outcomes',
      'At PATH project Start',
      'AT PATH project exit (for clients who were exited from PATH this year - leavers)',
      'At report end date (for clients who were still active in PATH as of report end date - stayers)',
    ].freeze

    ROW_LABELS = [
      '19. Income from any source',
      'Yes',
      'No',
      'Client doesn\'t know',
      'Client refused',
      'Data not collected',
      'Total',
      '20. SSI/SSDI',
      'Yes',
      'No',
      '21. Non-cash benefits from any source',
      'Yes',
      'No',
      'Client doesn\'t know',
      'Client refused',
      'Data not collected',
      'Total',
      '22. Covered by health insurance',
      'Yes',
      'No',
      'Client doesn\'t know',
      'Client refused',
      'Data not collected',
      'Total',
      '23. Medicaid/Medicare',
      'Yes',
      'No',
      '24. All other health insurance',
      'Yes',
      'No',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end
  end
end
