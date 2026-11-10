###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Builds a HUD assessment whose c_housing_assessment_name answer resolves to `name`,
# which is how GrdaWarehouse::Hud::Assessment#pathways_or_transfer? identifies Pathways and Transfer assessments.
module NamedHudAssessmentHelpers
  def create_named_hud_assessment(name, **assessment_attributes)
    assessment = create(:hud_assessment, **assessment_attributes)
    GrdaWarehouse::AssessmentAnswerLookup.create!(
      assessment_question: 'c_housing_assessment_name',
      response_code: assessment.AssessmentID.to_s,
      response_text: name,
    )
    create(
      :hud_assessment_question,
      data_source_id: assessment.data_source_id,
      AssessmentID: assessment.AssessmentID,
      AssessmentQuestion: 'c_housing_assessment_name',
      AssessmentAnswer: assessment.AssessmentID.to_s,
    )
    assessment
  end
end
