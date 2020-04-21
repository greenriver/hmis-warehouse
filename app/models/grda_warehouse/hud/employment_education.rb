###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class EmploymentEducation < Base
    include HudSharedScopes
    include ::HMIS::Structure::EmploymentEducation

    self.table_name = 'EmploymentEducation'
    self.hud_key = :EmploymentEducationID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :EmploymentEducationID,
          :ProjectEntryID,
          :PersonalID,
          :InformationDate,
          :LastGradeCompleted,
          :SchoolStatus,
          :Employed,
          :EmploymentType,
          :NotEmployedReason,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :EmploymentEducationID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :LastGradeCompleted,
          :SchoolStatus,
          :Employed,
          :EmploymentType,
          :NotEmployedReason,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :EmploymentEducationID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :LastGradeCompleted,
          :SchoolStatus,
          :Employed,
          :EmploymentType,
          :NotEmployedReason,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :EmploymentEducationID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :LastGradeCompleted,
          :SchoolStatus,
          :Employed,
          :EmploymentType,
          :NotEmployedReason,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :employment_educations
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_employment_educations
    has_one :client, through: :enrollment, inverse_of: :employment_educations
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :employment_educations, optional: true
    has_one :project, through: :enrollment
    belongs_to :data_source

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end

  end
end