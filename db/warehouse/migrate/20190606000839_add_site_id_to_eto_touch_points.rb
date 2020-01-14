class AddSiteIdToEtoTouchPoints < ActiveRecord::Migration[4.2]
  def change
    add_column :eto_touch_point_lookups, :site_id, :integer
  end
end
