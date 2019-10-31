class AddPaperTrailMetadataToUserViewableEntity < ActiveRecord::Migration[4.2]
  def change
    add_column :versions, :referenced_user_id, :integer
    add_column :versions, :referenced_entity_name, :string
  end
end
