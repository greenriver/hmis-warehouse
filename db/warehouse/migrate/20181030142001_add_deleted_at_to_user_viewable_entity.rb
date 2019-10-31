class AddDeletedAtToUserViewableEntity < ActiveRecord::Migration[4.2]
  def change
    add_column :user_viewable_entities, :deleted_at, :datetime, index: true
  end
end
