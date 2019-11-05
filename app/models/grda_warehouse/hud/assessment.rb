###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class Assessment < Base
    include HudSharedScopes
    self.table_name = :Assessment
    self.hud_key = :AssessmentID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        :AssessmentID,
        :EnrollmentID,
        :PersonalID,
        :AssessmentDate,
        :AssessmentLocation,
        :AssessmentType,
        :AssessmentLevel,
        :PrioritizationStatus,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ].freeze
    end

    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :assessments, optional: true
    belongs_to :enrollment, **hud_enrollment_belongs
    has_one :client, through: :enrollment, inverse_of: :assessments
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client')
    belongs_to :data_source
    has_many :assessment_questions, **hud_assoc(:AssessmentID, 'AssessmentQuestion')
    has_many :assessment_results, **hud_assoc(:AssessmentID, 'AssessmentResult')

  end
end
