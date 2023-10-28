class CreateTranslations < ActiveRecord::Migration[6.1]
  def change
    create_table :translations do |t|
      t.string :key, index: true
      t.string :text
      t.boolean :common, default: false, null: false
      t.timestamps
    end
  end
end
