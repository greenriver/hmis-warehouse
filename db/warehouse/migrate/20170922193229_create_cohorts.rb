class CreateCohorts < ActiveRecord::Migration[4.2]
  def change
    create_table :cohorts do |t|
      t.string :name, null: false
      t.timestamps null: false
      t.datetime :deleted_at, index: true
    end
  end
end
