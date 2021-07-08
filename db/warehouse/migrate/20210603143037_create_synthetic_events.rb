class CreateSyntheticEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :synthetic_events do |t|
      t.references :enrollment
      t.references :client
      t.string :type
      t.references :source, polymorphic: true

      t.timestamps
    end
  end
end
