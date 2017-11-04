class UpdateConfigCache < ActiveRecord::Migration
  def change
    config = GrdaWarehouse::Config.where(id: 1).first_or_create
    config.invalidate_cache
  end
end
