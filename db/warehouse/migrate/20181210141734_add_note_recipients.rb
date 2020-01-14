class AddNoteRecipients < ActiveRecord::Migration[4.2]
  def change
    add_column :client_notes, :recipients, :jsonb
    add_column :client_notes, :sent_at, :timestamp
  end
end
