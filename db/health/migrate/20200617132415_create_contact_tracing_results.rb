class CreateContactTracingResults < ActiveRecord::Migration[5.2]
  def change
    create_table :tracing_results do |t|
      t.references :contact

      t.string :test_result
      t.string :isolated
      t.string :isolation_location # Use locations?
      t.string :quarantine
      t.string :quarantine_location # Use locations?

      t.timestamp :deleted_at
      t.timestamps
    end
  end
end
