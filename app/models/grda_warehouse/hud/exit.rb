module GrdaWarehouse::Hud
  class Exit < Base
    self.table_name = 'Exit'
    self.hud_key = 'ExitID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "ExitID",
        "ProjectEntryID",
        "PersonalID",
        "ExitDate",
        "Destination",
        "OtherDestination",
        "AssessmentDisposition",
        "OtherDisposition",
        "HousingAssessment",
        "SubsidyInformation",
        "ConnectionWithSOAR",
        "WrittenAftercarePlan",
        "AssistanceMainstreamBenefits",
        "PermanentHousingPlacement",
        "TemporaryShelterPlacement",
        "ExitCounseling",
        "FurtherFollowUpServices",
        "ScheduledFollowUpContacts",
        "ResourcePackage",
        "OtherAftercarePlanOrAction",
        "ProjectCompletionStatus",
        "EarlyExitReason",
        "FamilyReunificationAchieved",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    belongs_to :data_source, inverse_of: :exits
    belongs_to :enrollment, **hud_belongs(Enrollment), inverse_of: :exit
    belongs_to :export, **hud_belongs(Export), inverse_of: :exits
  end
end