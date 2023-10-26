class CreateProcessedData < ActiveRecord::Migration[6.1]
  def change
    create_table :datasets do |t|
      t.references :source, polymorphic: true, null: false, index: true
      t.string :identifier
      t.jsonb :data
      t.timestamps
    end
  end
end
