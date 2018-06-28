module GrdaWarehouse::Import::HMISFiveOne
  class Exit < GrdaWarehouse::Hud::Exit
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :ExitID

    def self.file_name
      'Exit.csv'
    end

    def self.involved_exits(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        # Remove any exits that fall within the export range
        ids += self.joins(:project, :enrollment).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          where(ExitDate: range.range).
          pluck(:id)
      end
      ids
    end
  end
end