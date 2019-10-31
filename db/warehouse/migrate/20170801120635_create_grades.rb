class CreateGrades < ActiveRecord::Migration[4.2]
  def change
    create_table :grades do |t|
      t.string :type, null: false, index: true
      t.string :grade, null: false
      t.integer :percentage_low
      t.integer :percentage_high
      t.integer :percentage_under_low
      t.integer :percentage_under_high
      t.integer :percentage_over_low
      t.integer :percentage_over_high
      t.string :color, default: '#000000'
      t.integer :weight, null: false, default: 0
    end
  end
end
