class AddParentToHealthFile < ActiveRecord::Migration[4.2]
  def change
    add_column :health_files, :parent_id, :integer
  end
end
