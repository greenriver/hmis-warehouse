###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  scope :chronic, -> do
    where(ProjectType: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
  end

  scope :homeless, -> do
    where(ProjectType: GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)
  end

  scope :veteran, -> do
    where(veteran: true)
  end
end
