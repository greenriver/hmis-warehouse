class AddVisibleInWindowToDataSource < ActiveRecord::Migration[4.2]
  def change
    add_column :data_sources, :visible_in_window, :boolean, null: false, default: false
  end
end
