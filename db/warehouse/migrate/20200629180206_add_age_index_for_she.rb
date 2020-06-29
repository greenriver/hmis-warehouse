class AddAgeIndexForShe < ActiveRecord::Migration[5.2]
  # Concurrent indexes can't run in a transaction
  disable_ddl_transaction!

  def change
    begin
      add_index :service_history_enrollments, :age, algorithm: :concurrently
    rescue ArgumentError
      puts "Skipping adding age index to SHE, it already exists"
    end
  end
end
