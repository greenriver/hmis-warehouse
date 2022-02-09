###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouseBase < ApplicationRecord
  include ArelHelper
  include Efind

  self.abstract_class = true
  connects_to database: { writing: :warehouse, reading: :warehouse }

  def self.sql_server?
    connection.adapter_name == 'SQLServer'
  end

  def self.postgres?
    connection.adapter_name.in?(['PostgreSQL', 'PostGIS'])
  end

  def self.reset_connection
    self.connection.disconnect!
    self.establish_connection DB_WAREHOUSE
  end

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/warehouse/migrate', GrdaWarehouse::SchemaMigration).needs_migration?
  end
end
