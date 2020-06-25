###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Assessment < Base
    include HudSharedScopes
    include ::HMIS::Structure::Assessment

    attr_accessor :source_id

    self.table_name = :Assessment

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessments, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :client, through: :enrollment, inverse_of: :assessments
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source
    has_many :assessment_questions, **hud_assoc(:AssessmentID, 'AssessmentQuestion')
    has_many :assessment_results, **hud_assoc(:AssessmentID, 'AssessmentResult')

  end
end
