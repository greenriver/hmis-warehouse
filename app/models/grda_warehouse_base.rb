###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    connection.disconnect!
    establish_connection DB_WAREHOUSE
  end

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/warehouse/migrate', GrdaWarehouse::SchemaMigration).needs_migration?
  end

  def self.partitioned?(table_name)
    Dba::PartitionMaker.new(table_name: table_name).done?
  end

  # default colocated versions table for warehouse records
  def self.has_paper_trail(options = {}) # rubocop:disable Naming/PredicateName
    versions = options.fetch(:versions, {}).merge(class_name: 'GrdaWarehouse::Version')
    super(options.merge(versions: versions))
  end
end
