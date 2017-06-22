class SnapshotIsolationToGrdaWarehouse < ActiveRecord::Migration
  def change
    if GrdaWarehouseBase.connection.adapter_name == 'SQLServer'
      db = Rails.configuration.database_configuration["#{Rails.env}_grda_warehouse"]['database']
      sql = "ALTER DATABASE #{db} SET ALLOW_SNAPSHOT_ISOLATION ON"
      GrdaWarehouseBase.connection.execute(sql)
      sql = "ALTER DATABASE #{db} SET READ_COMMITTED_SNAPSHOT ON"
      GrdaWarehouseBase.connection.execute(sql)
    else
      puts 'Doing Nothing for Postgres'
    end
  end
end
