class GrdaWarehouseBase < ActiveRecord::Base
  establish_connection DB_WAREHOUSE
  self.abstract_class = true

  def self.sql_server?
    connection.adapter_name == 'SQLServer'
  end

  def self.postgres?
    connection.adapter_name == 'PostgreSQL'
  end
end
