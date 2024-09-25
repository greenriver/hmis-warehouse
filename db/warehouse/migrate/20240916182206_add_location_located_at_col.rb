class AddLocationLocatedAtCol < ActiveRecord::Migration[7.0]
  def change
    add_column :clh_locations, :located_at, :datetime, required: false
  end
end
