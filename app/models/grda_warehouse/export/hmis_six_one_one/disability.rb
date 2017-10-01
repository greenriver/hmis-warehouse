module GrdaWarehouse::Export::HMISSixOneOne
  class Disability < GrdaWarehouse::Import::HMISSixOneOne::Disability
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( 
      [
        :DisabilitiesID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :DisabilityType,
        :DisabilityResponse,
        :IndefiniteAndImpairs,
        :TCellCountAvailable,
        :TCellCount,
        :TCellSource,
        :ViralLoadAvailable,
        :ViralLoad,
        :ViralLoadSource,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :DisabilitiesID

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
      disability_scope = joins(:enrollment).merge(enrollment_scope).
        where(arel_table[:InformationDate].lteq(export.end_date))
      export_to_path(
        export_scope: enrollment_coc_scope, 
        path: path, 
        export: export
      )
    end
  end
end