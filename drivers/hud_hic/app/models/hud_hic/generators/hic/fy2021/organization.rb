###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudHic::Generators::Hic::Fy2021
  class Organization < ::HudReports::QuestionBase
    include ArelHelper
    include HudReports::Util

    QUESTION_NUMBER = 'Organization'.freeze
    def run_question!
    end
  end
end
