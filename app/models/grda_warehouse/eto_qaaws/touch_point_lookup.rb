module GrdaWarehouse::EtoQaaws
  class TouchPointLookup < GrdaWarehouseBase
    self.table_name = :eto_touch_point_lookups

    belongs_to :hmis_assessment, class_name: GrdaWarehouse::HMIS::Assessment.name, primary_key: [:data_source_id, :site_id, :assessment_id], foreign_key: [:data_source_id, :site_id, :assessment_id]
  end
end