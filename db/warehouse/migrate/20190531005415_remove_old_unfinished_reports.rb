class RemoveOldUnfinishedReports < ActiveRecord::Migration[4.2]
  def change
    GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionOne.where(completed_at: nil).update_all(completed_at: Time.now)
    GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionTwo.where(completed_at: nil).update_all(completed_at: Time.now)
    GrdaWarehouse::WarehouseReports::Project::DataQuality::VersionThree.where(completed_at: nil).update_all(completed_at: Time.now)
  end
end
