class AdditionalIndicesForShs < ActiveRecord::Migration[5.2]
  GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, table|
      begin
        add_index table, [:client_id, :service_history_enrollment_id], name: "index_shs_#{year}_c_id_en_id", algorithm: :concurrently
      rescue ArgumentError
        puts "Skipping index_shs_#{year}_client_id_only which already exists"
      end
    end
end
