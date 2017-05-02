# holds cached census data collected from the service history table
class GrdaWarehouse::CensusByProjectType < GrdaWarehouseBase
  include ArelHelper

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