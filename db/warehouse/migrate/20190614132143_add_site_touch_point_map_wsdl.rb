class AddSiteTouchPointMapWsdl < ActiveRecord::Migration[4.2]
  def change
    add_column :bo_configs, :site_touch_point_map_cuid, :string
  end
end
