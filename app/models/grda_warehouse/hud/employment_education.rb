module GrdaWarehouse::Hud
  class EmploymentEducation < Base
    self.table_name = 'EmploymentEducation'
    self.hud_key = 'EmploymentEducationID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "EmploymentEducationID",
        "ProjectEntryID",
        "PersonalID",
        "InformationDate",
        "LastGradeCompleted",
        "SchoolStatus",
        "Employed",
        "EmploymentType",
        "NotEmployedReason",
        "DataCollectionStage",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ].freeze
    end

    belongs_to :client, **hud_belongs(Client), inverse_of: :employment_educations
    belongs_to :export, **hud_belongs(Export), inverse_of: :employment_educations
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :employment_educations

  end
end