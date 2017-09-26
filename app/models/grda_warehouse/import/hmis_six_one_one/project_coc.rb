module GrdaWarehouse::Import::HMISSixOneOne
  class ProjectCoc < GrdaWarehouse::Hud::ProjectCoc
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :ProjectCoCID,
        :ProjectID,
        :CoCCode,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ProjectCoCID

    def self.file_name
      'ProjectCoC.csv'
    end
  end
end