class AddDeletionReasonToFiles < ActiveRecord::Migration[4.2]
  def change
    add_column :files, :delete_reason, :integer
  end
end
