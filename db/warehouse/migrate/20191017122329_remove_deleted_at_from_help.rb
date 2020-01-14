class RemoveDeletedAtFromHelp < ActiveRecord::Migration[4.2]
  def change
    remove_column :helps, :deleted_at, :datetime
  end
end
