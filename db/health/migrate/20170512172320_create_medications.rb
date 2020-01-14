class CreateMedications < ActiveRecord::Migration[4.2]
  def change
    create_table :medications do |t|
      t.date :start_date
      t.date :ordered_date
      t.text :name
      t.text :instructions
      t.timestamps null: false
      t.references :patient, index: true
    end
  end
end
