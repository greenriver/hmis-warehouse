# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# holds cached census data collected from the service history table
class GrdaWarehouse::CensusByProject < GrdaWarehouseBase
  include ArelHelper

  self.table_name = :censuses

  belongs_to_with_composite_keys :project, class_name: 'GrdaWarehouse::Hud::Project', keys: [:ProjectID], optional: true
  belongs_to_with_composite_keys :organization, class_name: 'GrdaWarehouse::Hud::Organization', keys: [:OrganizationID], optional: true
  scope :residential, -> { where(ProjectType: HudUtility2024.residential_project_type_numbers_by_code.values.flatten.uniq) }
  scope :for_year, ->(year) {
    fun = if postgres?
      nf 'date_part', ['year', arel_table[:date]]
    elsif sql_server?
      nf 'year', [arel_table[:date]]
    end
    where(fun.eq year)
  }
end
