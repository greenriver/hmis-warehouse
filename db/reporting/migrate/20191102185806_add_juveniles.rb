class AddJuveniles < ActiveRecord::Migration
  def change
    add_column :warehouse_returns, :juvenile, :boolean
  end
end
