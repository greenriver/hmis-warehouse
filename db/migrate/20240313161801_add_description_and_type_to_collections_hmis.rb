class AddDescriptionAndTypeToCollectionsHmis < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_access_groups, :description, :text
    add_column :hmis_access_groups, :collection_type, :string
    add_column :hmis_user_groups, :description, :text
    add_column :hmis_access_controls, :description, :text
  end
end
