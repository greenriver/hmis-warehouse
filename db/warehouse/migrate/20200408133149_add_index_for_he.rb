class AddIndexForHe < ActiveRecord::Migration[5.2]
  def change
    add_index :health_emergency_isolations, :location
  end
end
