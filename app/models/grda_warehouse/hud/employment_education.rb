module GrdaWarehouse::Hud
  class EmploymentEducation < Base
    include HudSharedScopes
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

    belongs_to :direct_client, **hud_belongs(Client), inverse_of: :direct_employment_educations
    has_one :client, through: :enrollment, inverse_of: :employment_educations
    belongs_to :export, **hud_belongs(Export), inverse_of: :employment_educations
    belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], inverse_of: :employment_educations
    has_one :project, through: :enrollment

  end
end