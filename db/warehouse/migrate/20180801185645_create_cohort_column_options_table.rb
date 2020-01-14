class CreateCohortColumnOptionsTable < ActiveRecord::Migration[4.2]
  def change
    create_table :cohort_column_options do |t|
      t.string :cohort_column, null: false
      t.integer :weight
      t.string :value
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
