class AddScheduledHourToScheduledDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :scheduled_documents, :scheduled_hour, :integer
  end
end
