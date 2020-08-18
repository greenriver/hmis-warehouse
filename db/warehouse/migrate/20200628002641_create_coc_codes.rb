class CreateCoCCodes < ActiveRecord::Migration[5.2]
  def change
    create_table :coc_codes do |t|
      t.string :coc_code, index: true, null: false
      t.string :official_name, null: false
      t.string :preferred_name
      t.boolean :active, default: true, null: false
      t.timestamps
    end
  end
end
