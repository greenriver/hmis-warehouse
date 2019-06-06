class AddSiteIdToEtoTouchPoints < ActiveRecord::Migration
  def change
    add_column :eto_touch_point_lookups, :site_id, :integer
  end
end
