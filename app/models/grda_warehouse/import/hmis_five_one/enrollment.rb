module GrdaWarehouse::Import::HMISFiveOne
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include ::Import::HMISFiveOne::Shared
    include TsqlImport

    setup_hud_column_access( self.hud_csv_headers(version: '5.1') )

    self.hud_key = :ProjectEntryID

    def self.file_name
      'Enrollment.csv'
    end

    def self.unique_constraint
      [self.hud_key, :data_source_id, :PersonalID]
    end

    def self.involved_enrollments(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        ids += self.joins(:project).
          open_during_range(range).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          pluck(:id)
      end
      ids
    end
  end
end