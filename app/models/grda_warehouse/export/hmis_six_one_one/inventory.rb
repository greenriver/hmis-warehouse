module GrdaWarehouse::Export::HMISSixOneOne
  class Inventory < GrdaWarehouse::Import::HMISSixOneOne::Inventory
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :InventoryID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :HouseholdType,
        :Availability,
        :UnitInventory,
        :BedInventory,
        :CHBedInventory,
        :VetBedInventory,
        :YouthBedInventory,
        :BedType,
        :InventoryStartDate,
        :InventoryEndDate,
        :HMISParticipatingBeds,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :InventoryID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :inventories

    def self.export! project_scope:, path:, export:
      if export.include_deleted
        inventory_scope = joins(:project_with_deleted).merge(project_scope)
      else
        inventory_scope = joins(:project).merge(project_scope)
      end
      export_to_path(export_scope: inventory_scope, path: path, export: export)
    end
  end
end