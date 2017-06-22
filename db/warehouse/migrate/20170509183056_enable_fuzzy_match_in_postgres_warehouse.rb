class EnableFuzzyMatchInPostgresWarehouse < ActiveRecord::Migration
  def change
    if GrdaWarehouseBase.connection.adapter_name == 'PostgreSQL'
      enable_extension "fuzzystrmatch"
    end
  end
end
