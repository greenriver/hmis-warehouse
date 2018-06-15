class AddCohortColumnsToClientsProcessed < ActiveRecord::Migration
  def change
    add_column :warehouse_clients_processed, :disability_verification_date, :date
    add_column :warehouse_clients_processed, :enrolled_homeless_shelter, :boolean
    add_column :warehouse_clients_processed, :enrolled_homeless_unsheltered, :boolean
    add_column :warehouse_clients_processed, :enrolled_permanent_housing, :boolean
    add_column :warehouse_clients_processed, :eto_coordinated_entry_assessment_score, :decimal
    add_column :warehouse_clients_processed, :household_members, :string
    add_column :warehouse_clients_processed, :last_homeless_visit, :string
    add_column :warehouse_clients_processed, :missing_documents, :string
    add_column :warehouse_clients_processed, :open_enrollments, :jsonb
    add_column :warehouse_clients_processed, :rrh_desired, :boolean
    add_column :warehouse_clients_processed, :vispdat_priority_score, :decimal
    add_column :warehouse_clients_processed, :vispdat_score, :decimal
  end
end
