module GrdaWarehouse::Export::HMISSixOneOne
  class Affiliation < GrdaWarehouse::Import::HMISSixOneOne::Affiliation
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Affiliation.hud_csv_headers(version: '6.11') )

    self.hud_key = :AffiliationID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :affiliations

  end
end