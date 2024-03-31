class AddDescriptionAndTypeToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :description, :text
    add_column :collections, :collection_type, :string
    add_column :user_groups, :description, :text
    add_column :access_controls, :description, :text
  end
end
