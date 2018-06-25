class RemoveClientProcessedFieldsUsedInCohorts < ActiveRecord::Migration
  def change
    remove_column :warehouse_clients_processed, :disability_verification_date, :date
    remove_column :warehouse_clients_processed, :missing_documents, :string
  end
end
