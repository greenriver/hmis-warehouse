module GrdaWarehouse::Import::HMISFiveOne
  class ProjectCoc < GrdaWarehouse::Hud::ProjectCoc
    include ::Import::HMISFiveOne::Shared
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