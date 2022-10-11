class AddEncampmentDecomissioningToClient < ActiveRecord::Migration[6.1]
  def change
    add_column :Client, :encampment_decomissioned, :boolean, default: false, null: false
  end
end
