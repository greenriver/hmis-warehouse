###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentQuestion < Base
    include HudSharedScopes
    self.table_name = :AssessmentQuestions
    self.hud_key = :AssessmentQuestionID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :AssessmentQuestionID,
        :AssessmentID,
        :EnrollmentID,
        :PersonalID,
        :AssessmentQuestionGroup,
        :AssessmentQuestionOrder,
        :AssessmentQuestion,
        :AssessmentAnswer,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
        :data_source_id,
      ].freeze
    end

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessment_questions
    belongs_to :enrollment, **hud_enrollment_belongs
    belongs_to :client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :assessment, **hud_assoc(:AssessmentID, 'Assessment')
    belongs_to :data_source

  end
end
