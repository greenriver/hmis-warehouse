class EnablePgCryptoModule < ActiveRecord::Migration
  def change
    if GrdaWarehouseBase.connection.adapter_name == 'PostgreSQL'
      enable_extension "pgcrypto"
    end
  end
end
