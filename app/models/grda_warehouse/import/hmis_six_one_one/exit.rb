module GrdaWarehouse::Import::HMISSixOneOne
  class Exit < GrdaWarehouse::Hud::Exit
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :ExitID
    setup_hud_column_access( GrdaWarehouse::Hud::Exit.hud_csv_headers(version: '6.11') )

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

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :ExitDate,
        data_source_id: :data_source_id,
      }
    end
  end
end