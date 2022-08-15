###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2021
  class QuestionFour < HudApr::Generators::Shared::Fy2021::QuestionFour
    include HudApr::Generators::CeApr::Fy2021::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    def needs_ce_assessments?
      true
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end

    # CE APR should only include projects where there are assessments or events within the range
    # as noted in the spec:
    # Be sure to include data on all projects with clients and enrollments included on any question in this APR.
    private def q4_project_scope
      active_project_ids = @generator.active_project_ids
      active_project_ids = @report.project_ids if active_project_ids.blank?
      GrdaWarehouse::Hud::Project.where(id: active_project_ids)
    end
  end
end
