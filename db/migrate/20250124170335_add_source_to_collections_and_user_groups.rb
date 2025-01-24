class AddSourceToCollectionsAndUserGroups < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_reference :collections, :source, polymorphic: true, index: {algorithm: :concurrently}
    add_reference :user_groups, :source, polymorphic: true, index: {algorithm: :concurrently}
    add_column :user_groups, :context, :string
  end
end
