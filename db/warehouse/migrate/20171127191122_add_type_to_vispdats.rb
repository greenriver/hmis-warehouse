class AddTypeToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :type, :string, default: "GrdaWarehouse::Vispdat::Individual"
  end
end
