module GrdaWarehouse::Export::HMISSixOneOne
  class Disability < GrdaWarehouse::Import::HMISSixOneOne::Disability
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( 
      [
        :DisabilitiesID,
        :ProjectEntryID,
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

    # Setup an association to enrollment that allows us to pull the records even if the 
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id]

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