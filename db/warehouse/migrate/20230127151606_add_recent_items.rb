class AddRecentItems < ActiveRecord::Migration[6.1]
  def change
    create_table :recent_items do |t|
      t.references :owner, null: false, polymorphic: true
      t.references :item, null: false, polymorphic: true
      t.timestamps
    end
  end
end
