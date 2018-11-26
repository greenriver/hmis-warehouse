module GrdaWarehouse::Import::HMISSixOneOne
  class Funder < GrdaWarehouse::Hud::Funder
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    self.hud_key = :FunderID
    setup_hud_column_access( GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '6.11') )

    def self.file_name
      'Funder.csv'
    end

    # Each import should be authoritative for funder for all projects included
    def self.delete_involved projects:, range:, data_source_id:, deleted_at:
      deleted_count = 0
      projects.each do |project|
        del_scope = self.where(ProjectID: project.ProjectID, data_source_id: data_source_id)
        deleted_count += del_scope.update_all(DateDeleted: deleted_at)
      end
      deleted_count
    end

  end
end