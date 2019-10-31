class AddPreCalculatedAtToClaim < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :claims, :precalculated_at, :datetime
  end
end
