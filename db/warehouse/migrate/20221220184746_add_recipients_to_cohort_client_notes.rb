class AddRecipientsToCohortClientNotes < ActiveRecord::Migration[6.1]
  def change
    add_column :cohort_client_notes, :recipients, :jsonb, default: []
  end
end
