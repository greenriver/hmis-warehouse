class AddDeletedAtToClientNotes < ActiveRecord::Migration
  def change
    add_column :client_notes, :deleted_at, :datetime
  end
end
