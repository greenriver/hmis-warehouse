class AddTypeToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :type, :string, default: "GrdaWarehouse::Vispdat::Individual"
  end
end
