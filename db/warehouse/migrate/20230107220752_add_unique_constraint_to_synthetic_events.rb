class AddUniqueConstraintToSyntheticEvents < ActiveRecord::Migration[6.1]
  def change
    add_index :synthetic_events, [:source_id, :source_type], unique: true
  end
end
