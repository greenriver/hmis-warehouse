###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentQuestion < Base
    include HudSharedScopes
    include ::HMIS::Structure::AssessmentQuestion
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :AssessmentQuestions
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessment_questions, optional: true
    belongs_to :assessment, **hud_assoc(:AssessmentID, 'Assessment'), optional: true
    belongs_to :direct_enrollment, **hud_enrollment_belongs, optional: true
    has_one :enrollment, through: :assessment
    has_one :client, through: :assessments, inverse_of: :assessment_questions
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), optional: true

    belongs_to :data_source

  end
end
