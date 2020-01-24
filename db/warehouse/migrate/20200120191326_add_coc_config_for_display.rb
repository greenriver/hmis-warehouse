class AddCoCConfigForDisplay < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :expose_coc_code, :boolean, default: false, null: false
    GrdaWarehouse::Config.invalidate_cache
  end
end
