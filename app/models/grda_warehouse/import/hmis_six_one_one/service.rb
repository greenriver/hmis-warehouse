module GrdaWarehouse::Import::HMISSixOneOne
  class Service < GrdaWarehouse::Hud::Service
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
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
    def self.date_provided_column 
      :DateProvided
    end
    
    def self.file_name
      'Services.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :DateProvided,
        data_source_id: :data_source_id,
      }
    end
  end
end