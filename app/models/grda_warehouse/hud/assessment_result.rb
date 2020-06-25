###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentResult < Base
    include HudSharedScopes
    include ::HMIS::Structure::AssessmentResult

    attr_accessor :source_id

    self.table_name = :AssessmentResults
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessment_results, optional: true
    belongs_to :assessment, **hud_assoc(:AssessmentID, 'Assessment')
    belongs_to :direct_enrollment, **hud_enrollment_belongs
    has_one :enrollment, through: :assessment
    has_one :client, through: :assessments, inverse_of: :assessment_results
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')


    belongs_to :data_source

  end
end
