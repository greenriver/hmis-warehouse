class AddDmhToChronics < ActiveRecord::Migration
  def change
    add_column :chronics, :dmh, :boolean, default: false
  end
end
