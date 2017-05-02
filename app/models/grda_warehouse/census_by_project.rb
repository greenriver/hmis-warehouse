# holds cached census data collected from the service history table
class GrdaWarehouse::CensusByProject < GrdaWarehouseBase
  include ArelHelper

  self.table_name = :censuses

  belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: [:data_source_id, :ProjectID], primary_key: [:data_source_id, :ProjectID]
  belongs_to :organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: [:data_source_id, :OrganizationID], primary_key: [:data_source_id, :OrganizationID]
  scope :residential, -> { where(ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES.values.flatten.uniq) }
  scope :for_year, -> (year) {
    fun = if postgres?
      nf 'date_part', [ 'year', arel_table[:date] ]
    elsif sql_server?
      nf 'year', [ arel_table[:date] ]
    end
    where( fun.eq year )
  }
end