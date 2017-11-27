class AddAharpshConfig < ActiveRecord::Migration
  def change
    add_column :configs, :ahar_psh_includes_rrh, :boolean, default: true
    GrdaWarehouse::Config.invalidate_cache
    GrdaWarehouse::Config.first.update(ahar_psh_includes_rrh: true)
  end
end
