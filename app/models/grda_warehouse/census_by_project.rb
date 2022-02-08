###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# holds cached census data collected from the service history table
class GrdaWarehouse::CensusByProject < GrdaWarehouseBase
  include ArelHelper

  self.table_name = :censuses

  belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: [:data_source_id, :ProjectID], primary_key: [:data_source_id, :ProjectID], optional: true
  belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', foreign_key: [:data_source_id, :OrganizationID], primary_key: [:data_source_id, :OrganizationID], optional: true
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
