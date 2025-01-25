class AddSourceToCollectionsAndUserGroups < ActiveRecord::Migration[7.0]
  def change
    safety_assured do
      add_reference :collections, :source, polymorphic: true, index: { unique: true }
      add_reference :user_groups, :source, polymorphic: true
    end
    add_column :user_groups, :context, :string
  end
end
