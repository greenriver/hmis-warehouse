class AddActiveToVispdats < ActiveRecord::Migration
  def change
    add_column :vispdats, :active, :boolean, default: false
  end
end
