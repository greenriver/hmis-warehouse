class CreateImports < ActiveRecord::Migration
  def change
    create_table :imports do |t|
      t.string :file
      t.string :source
      t.float :percent_complete
      t.timestamps null: false
      t.datetime :completed_at
      t.datetime :deleted_at, index: true, null: true
    end
  end
end
