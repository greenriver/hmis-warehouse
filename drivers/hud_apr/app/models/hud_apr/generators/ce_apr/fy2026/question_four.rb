###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudApr::Generators::CeApr::Fy2026
  class QuestionFour < HudApr::Generators::Shared::Fy2026::QuestionFour
    include HudApr::Generators::CeApr::Fy2026::QuestionConcern
    QUESTION_TABLE_NUMBERS = ['Q4a'].freeze

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q4_project_identifiers

      @report.complete(QUESTION_NUMBER)
    end

    # Q4 lists all projects in the CE APR report universe (spec step 2: projects in the chosen CoC
    # with ContinuumProject = 1 and active CE participation). active_project_ids (from the generator)
    # computes this universe by requiring assessments or events in range; if none qualify, we fall back
    # to the full report project list. Either way, .continuum_project enforces step 1.a
    # (ContinuumProject = 1) so non-continuum projects can never appear in Q4.
    private def q4_project_scope
      active_project_ids = @generator.active_project_ids
      # active_project_ids is empty when no projects have qualifying assessments/events;
      # fall back to the full report selection so Q4 still lists participating projects.
      active_project_ids = if active_project_ids.blank?
        @report.project_ids
      else
        active_project_ids & @report.project_ids
      end
      GrdaWarehouse::Hud::Project.where(id: active_project_ids).continuum_project # step 1.a: ContinuumProject = 1
    end
  end
end
