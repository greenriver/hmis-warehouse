class AddDmhToChronics < ActiveRecord::Migration[4.2]
  def change
    add_column :chronics, :dmh, :boolean, default: false
  end
end
