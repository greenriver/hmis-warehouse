class AddParentToHealthFile < ActiveRecord::Migration
  def change
    add_column :health_files, :parent_id, :integer
  end
end
