class AddPreCalculatedAtToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :precalculated_at, :datetime
  end
end
