module GrdaWarehouse::Export::HMISSixOneOne
  class EmploymentEducation < GrdaWarehouse::Import::HMISSixOneOne::EmploymentEducation
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
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
      ]
    )
    
    self.hud_key = :EmploymentEducationID
  end
end