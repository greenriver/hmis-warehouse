###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class GrdaWarehouseBase < ActiveRecord::Base
  include ArelHelper
  establish_connection DB_WAREHOUSE
  self.abstract_class = true

  def self.sql_server?
    connection.adapter_name == 'SQLServer'
  end

  def self.postgres?
    connection.adapter_name == 'PostgreSQL'
  end

  def self.reset_connection
    self.connection.disconnect!
    self.establish_connection DB_WAREHOUSE
  end
end
