class AddActiveToScheduledDocuments < ActiveRecord::Migration[5.2]
  def change
    add_column :scheduled_documents, :active, :boolean, default: true
  end
end
