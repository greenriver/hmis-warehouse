class CreateChEnrollments < ActiveRecord::Migration[5.2]
  def change
    create_table :ch_enrollments do |t|
      t.references :enrollment, null: false, index: true
      t.string :processed_as
      t.boolean :chronically_homeless_at_entry, default: false, null: false
      t.timestamps null: false
    end
  end
end
