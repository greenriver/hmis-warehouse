module GrdaWarehouse::Export::HMISSixOneOne
  class HealthAndDv < GrdaWarehouse::Import::HMISSixOneOne::HealthAndDv
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :HealthAndDVID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :DomesticViolenceVictim,
        :WhenOccurred,
        :CurrentlyFleeing,
        :GeneralHealthStatus,
        :DentalHealthStatus,
        :MentalHealthStatus,
        :PregnancyStatus,
        :DueDate,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :HealthAndDVID

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