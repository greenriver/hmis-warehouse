class AddPlaceIndexes < ActiveRecord::Migration[6.1]
  def change
    # Small table
    safety_assured do
      add_index :clh_locations, [:lat, :lon]
    end
  end
end
