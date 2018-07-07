module GrdaWarehouse::Export::HMISSixOneOne
  class Funder < GrdaWarehouse::Import::HMISSixOneOne::Funder
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Funder.hud_csv_headers(version: '6.11') )

    self.hud_key = :FunderID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :funders
  end
end