###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::EtoQaaws
  class TouchPointLookup < GrdaWarehouseBase
    self.table_name = :eto_touch_point_lookups

    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource', optional: true
    belongs_to :hmis_assessment, class_name: 'GrdaWarehouse::Hmis::Assessment', primary_key: [:data_source_id, :site_id, :assessment_id], foreign_key: [:data_source_id, :site_id, :assessment_id], optional: true
  end
end
