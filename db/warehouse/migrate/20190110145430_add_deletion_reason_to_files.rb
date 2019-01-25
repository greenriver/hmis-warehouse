class AddDeletionReasonToFiles < ActiveRecord::Migration
  def change
    add_column :files, :delete_reason, :integer
  end
end
