class ImproveDbPerformance < ActiveRecord::Migration[5.2]
  # Concurrent indexes can't run in a transaction
  disable_ddl_transaction!

  def change
    GrdaWarehouse::ServiceHistoryService.sub_tables.each do |year, table|

      begin
        add_index table, [:client_id], name: "index_shs_#{year}_client_id_only", algorithm: :concurrently
      rescue ArgumentError
        puts "Skipping index_shs_#{year}_client_id_only which already exists"
      end

      begin
        add_index table, [:service_history_enrollment_id], name: "index_shs_#{year}_en_id_only", algorithm: :concurrently
      rescue ArgumentError
        puts "Skipping index_shs_#{year}_en_id_only which already exists"
      end

      conditionally_add_statistics_if_supported(year, table)
    end

    begin
      add_index :warehouse_clients_processed, :client_id, algorithm: :concurrently
    rescue ArgumentError
      puts "Skipping existing index on warehouse_clients_processed"
    end

    begin
      add_index :warehouse_clients, :data_source_id, algorithm: :concurrently
    rescue ArgumentError
      puts "Skipping existing index on warehouse_clients"
    end

    begin
      add_index :ProjectCoC, :data_source_id, algorithm: :concurrently
    rescue ArgumentError
      puts "Skipping existing index on ProjectCoC"
    end
  end

  def conditionally_add_statistics_if_supported(year, table)
    version_string = ApplicationRecord.connection.execute('select version()').first['version'] rescue 'unknown'

    if match = version_string.match(/PostgreSQL (?<major_version>\d+)\.\d+ /)
      if match['major_version'].to_i >= 12
        reversible do |r|
          r.up do
            execute(<<~SQL)
              CREATE STATISTICS IF NOT EXISTS stats_shs_#{year}_homeless
              ON homeless, literally_homeless
              FROM #{table}
            SQL

            execute(<<~SQL)
              CREATE STATISTICS IF NOT EXISTS stats_shs_#{year}_age_homeless
              ON age, homeless
              FROM #{table}
            SQL

            execute(<<~SQL)
              CREATE STATISTICS IF NOT EXISTS stats_shs_#{year}_age_literally_homeless
              ON age, literally_homeless
              FROM #{table}
            SQL
          end

          r.down do
            execute("DROP STATISTICS stats_shs_#{year}_age_literally_homeless")
            execute("DROP STATISTICS stats_shs_#{year}_age_homeless")
            execute("DROP STATISTICS stats_shs_#{year}_homeless")
          end
        end
      end
    end
  end
end
