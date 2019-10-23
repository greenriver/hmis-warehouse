class RemoveDeletedAtFromHelp < ActiveRecord::Migration
  def change
    remove_column :helps, :deleted_at, :datetime
  end
end
