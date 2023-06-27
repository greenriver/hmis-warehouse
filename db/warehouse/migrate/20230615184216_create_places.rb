class CreatePlaces < ActiveRecord::Migration[6.1]
  def change
    create_table :places do |t|
      t.string :location, index: true, unique: true, null: false
      t.jsonb :lat_lon

      t.timestamps
    end
  end
end
