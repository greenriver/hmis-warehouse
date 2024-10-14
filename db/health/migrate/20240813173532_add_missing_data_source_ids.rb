class AddMissingDataSourceIds < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!
  def change
    add_reference :epic_housing_statuses, :data_source, index: {algorithm: :concurrently}
    add_reference :thrive_assessments, :data_source, index: {algorithm: :concurrently}
    add_reference :qualifying_activities, :data_source, index: {algorithm: :concurrently}
  end
end
