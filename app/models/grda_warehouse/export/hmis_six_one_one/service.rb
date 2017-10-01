module GrdaWarehouse::Export::HMISSixOneOne
  class Service < GrdaWarehouse::Import::HMISSixOneOne::Service
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :ServicesID,
        :EnrollmentID,
        :PersonalID,
        :DateProvided,
        :RecordType,
        :TypeProvided,
        :OtherTypeProvided,
        :SubTypeProvided,
        :FAAmount,
        :ReferralOutcome,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ServicesID

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