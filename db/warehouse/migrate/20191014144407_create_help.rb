class CreateHelp < ActiveRecord::Migration
  def change
    create_table :helps do |t|
      t.string :path, null: false
      t.string :external_url
      t.string :title, null: false
      t.text :content, null: false

      t.timestamps null: false, index: true
      t.datetime :deleted_at
    end

    add_index :helps, :path, unique: true
  end
end
