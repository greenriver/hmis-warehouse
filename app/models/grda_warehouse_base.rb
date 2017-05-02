class GrdaWarehouseBase < ActiveRecord::Base
  establish_connection "#{Rails.env}_grda_warehouse".parameterize.underscore.to_sym
  self.abstract_class = true

  def self.sql_server?
    connection.adapter_name == 'SQLServer'
  end

  def self.postgres?
    connection.adapter_name == 'PostgreSQL'
  end
end
