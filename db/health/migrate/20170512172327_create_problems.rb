class CreateProblems < ActiveRecord::Migration[4.2][4.2]
  def change
    create_table :problems do |t|
      t.date :onset_date
      t.date :last_assessed
      t.text :name
      t.text :comment
      t.string :icd10_list
      t.timestamps null: false
      t.references :patient, index: true
    end
  end
end
