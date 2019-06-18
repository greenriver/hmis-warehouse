class AddSiteTouchPointMapWsdl < ActiveRecord::Migration
  def change
    add_column :bo_configs, :site_touch_point_map_cuid, :string
  end
end
