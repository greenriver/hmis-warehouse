###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Assessment < Base
    include HudSharedScopes
    include ::HMIS::Structure::Assessment

    self.table_name = :Assessment
    self.hud_key = :AssessmentID
    acts_as_paranoid column: :DateDeleted

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessments, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :client, through: :enrollment, inverse_of: :assessments
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source
    has_many :assessment_questions, **hud_assoc(:AssessmentID, 'AssessmentQuestion')
    has_many :assessment_results, **hud_assoc(:AssessmentID, 'AssessmentResult')

  end
end
