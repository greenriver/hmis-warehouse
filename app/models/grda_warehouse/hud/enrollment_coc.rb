module GrdaWarehouse::Hud
  class EnrollmentCoc < Base
    self.table_name = 'EnrollmentCoC'
    self.hud_key = 'EnrollmentCoCID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "EnrollmentCoCID",
        "ProjectEntryID",
        "HouseholdID",
        "ProjectID",
        "PersonalID",
        "InformationDate",
        "CoCCode",
        "DataCollectionStage",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :project, **hud_belongs(Project), inverse_of: :enrollment_cocs
    belongs_to :client, **hud_belongs(Client), inverse_of: :enrollment_cocs
    belongs_to :export, **hud_belongs(Export), inverse_of: :enrollment_cocs
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :enrollment_cocs
  end
end