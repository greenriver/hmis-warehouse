###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# holds cached census data collected from the service history table
class GrdaWarehouse::CensusByProject < GrdaWarehouseBase
  include ArelHelper

  self.table_name = :censuses

  belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: [:data_source_id, :ProjectID], primary_key: [:data_source_id, :ProjectID], optional: true
  belongs_to :organization, class_name: 'GrdaWarehouse::Hud::Organization', foreign_key: [:data_source_id, :OrganizationID], primary_key: [:data_source_id, :OrganizationID], optional: true
  scope :residential, -> { where(ProjectType: HudHelper.util.residential_project_type_numbers_by_code.values.flatten.uniq) }
  scope :for_year, ->(year) {
    fun = if postgres?
      nf 'date_part', ['year', arel_table[:date]]
    elsif sql_server?
      nf 'year', [arel_table[:date]]
    end
    where(fun.eq year)
  }
end
