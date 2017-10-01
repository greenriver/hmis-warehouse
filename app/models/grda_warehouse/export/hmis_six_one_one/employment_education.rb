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

    # Replace 5.1 versions with 6.11
    # ProjectEntryID with EnrollmentID etc.
    def self.clean_headers(headers)
      headers.map do |k|
        case k
        when :ProjectEntryID
          :EnrollmentID
        else
          k
        end
      end
    end
  end
end