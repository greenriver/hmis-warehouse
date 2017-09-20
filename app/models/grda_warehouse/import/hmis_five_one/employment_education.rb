module GrdaWarehouse::Import::HMISFiveOne
  class EmploymentEducation < GrdaWarehouse::Hud::EmploymentEducation
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
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
        :ExportID,
      ]
    )
    
    self.hud_key = :EmploymentEducationID

    def self.file_name
      'EmploymentEducation.csv'
    end
    
  end
end