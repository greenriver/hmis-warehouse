class AddMultiCoCToConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :multi_coc_installation, :boolean, default: false, null: false
  end
end
