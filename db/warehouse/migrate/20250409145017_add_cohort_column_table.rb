class AddCohortColumnTable < ActiveRecord::Migration[7.0]
  def change
    create_table :cohort_column_types do |t|
      t.string :class_name
      t.boolean :active, default: true
    end
  end
end
