module GrdaWarehouse::Export::HMISSixOneOne
  class Geography < GrdaWarehouse::Import::HMISSixOneOne::Geography
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Geography.hud_csv_headers(version: '6.11') )

    self.hud_key = :GeographyID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :geographies


  end
end