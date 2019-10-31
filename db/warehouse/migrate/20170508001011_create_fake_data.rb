class CreateFakeData < ActiveRecord::Migration[4.2]
  def change
    create_table :fake_data do |t|
      t.string :environment, null: false
      t.text :map
      t.timestamps null: false
    end
  end
end
