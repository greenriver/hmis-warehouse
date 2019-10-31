class AddDeletedAtToClientNotes < ActiveRecord::Migration[4.2]
  def change
    add_column :client_notes, :deleted_at, :datetime
  end
end
