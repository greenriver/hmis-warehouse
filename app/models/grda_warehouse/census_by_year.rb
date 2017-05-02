# holds aggregated data similar to that from the census table -- see the census rake tasks
class GrdaWarehouse::CensusByYear < GrdaWarehouseBase
  self.table_name = :censuses_averaged_by_year

  belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: [:data_source_id, :ProjectID]
  belongs_to :organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: [:data_source_id, :OrganizationID]

  scope :residential, -> { where(ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values.flatten.uniq) }
end