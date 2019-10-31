class AddWeather < ActiveRecord::Migration[4.2]
  def change
    create_table :weather do |t|
      t.string :url, index: true, null: false
      t.text :body, null: false
      t.timestamps null: false
    end
  end
end
