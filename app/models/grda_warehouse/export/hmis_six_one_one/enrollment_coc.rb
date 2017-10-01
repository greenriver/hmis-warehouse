module GrdaWarehouse::Export::HMISSixOneOne
  class EnrollmentCoc < GrdaWarehouse::Import::HMISSixOneOne::EnrollmentCoc
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :EnrollmentCoCID,
        :ProjectEntryID,
        :HouseholdID,
        :ProjectID,
        :PersonalID,
        :InformationDate,
        :CoCCode,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :EnrollmentCoCID

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
    
    def self.export! enrollment_scope:, path:, export:
      # FIXME:
      # Needs enrollment scope with dates involved and without so we
      # Can union with those modified during that range
      enrollment_coc_scope = joins(:enrollment).merge(enrollment_scope)
      export_to_path(
        export_scope: enrollment_coc_scope, 
        path: path, 
        export: export
      )
    end
  end
end