class CreateHmisForms < ActiveRecord::Migration
  def change
    create_table :hmis_forms do |t|
      t.references :client
      t.text :response
      t.string :name
      t.text :answers
      t.timestamps null: false
    end
  end
end
