class AddNameConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :warehouse_client_name_order, :string, default: :earliest, null: false
  end
end
