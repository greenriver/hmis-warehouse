class SetExistingConfigPfReport < ActiveRecord::Migration[5.2]
  def up
    ProjectPassFail::ProjectPassFail.where(thresholds: {}).update_all(
      thresholds: {
        universal_data_element_threshold: GrdaWarehouse::Config.get(:pf_universal_data_element_threshold),
        utilization_range_min: GrdaWarehouse::Config.get(:pf_utilization_min),
        utilization_range_max: GrdaWarehouse::Config.get(:pf_utilization_max),
        timeliness_threshold: GrdaWarehouse::Config.get(:pf_timeliness_threshold),
      }
    )
  end
end
