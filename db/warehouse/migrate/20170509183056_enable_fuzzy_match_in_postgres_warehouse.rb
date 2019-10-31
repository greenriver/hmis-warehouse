class EnableFuzzyMatchInPostgresWarehouse < ActiveRecord::Migration[4.2]
  def change
    if GrdaWarehouseBase.connection.adapter_name == 'PostgreSQL'
      enable_extension "fuzzystrmatch"
    end
  end
end
