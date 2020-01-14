class AddActiveToVispdats < ActiveRecord::Migration[4.2]
  def change
    add_column :vispdats, :active, :boolean, default: false
  end
end
