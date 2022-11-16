class CreateLinks < ActiveRecord::Migration[6.1]
  def change
    create_table :links do |t|
      t.string :location
      t.string :url
      t.string :label
      t.string :subject
      t.timestamps
    end
  end
end
