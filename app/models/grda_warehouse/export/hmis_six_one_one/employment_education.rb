module GrdaWarehouse::Export::HMISSixOneOne
  class EmploymentEducation < GrdaWarehouse::Hud::EmploymentEducation
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
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
    
    def self.date_provided_column 
      :InformationDate
    end

    def self.file_name
      'EmploymentEducation.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end
    
  end
end