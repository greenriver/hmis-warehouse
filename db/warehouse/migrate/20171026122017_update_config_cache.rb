class UpdateConfigCache < ActiveRecord::Migration
  def change
    config = GrdaWarehouse::Config.find(1)
    config.invalidate_cache
  end
end
