###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class AssessmentResult < Base
    include HudSharedScopes
    include ::HMIS::Structure::AssessmentResult
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = :AssessmentResults
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessment_results, optional: true
    belongs_to :assessment, **hud_assoc(:AssessmentID, 'Assessment'), optional: true
    belongs_to :direct_enrollment, **hud_enrollment_belongs, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :assessment_results, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :enrollment, through: :assessment
    has_one :client, through: :assessment, inverse_of: :assessment_results
  end
end
