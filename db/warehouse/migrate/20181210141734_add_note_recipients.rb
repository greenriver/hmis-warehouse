class AddNoteRecipients < ActiveRecord::Migration
  def change
    add_column :client_notes, :recipients, :jsonb
    add_column :client_notes, :sent_at, :timestamp
  end
end
