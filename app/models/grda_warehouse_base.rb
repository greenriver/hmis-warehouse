###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouseBase < ActiveRecord::Base
  include ArelHelper
  include  Efind
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

  def self.setup_config
    new_config = {
      'db' => ['db/warehouse'],
      'db/migrate' => ['db/warehouse/migrate'],
      'db/seeds' => ['db/warehouse/seeds'],
      'config/database' => ['config/database_warehouse.yml'],
    }
    ENV['SCHEMA'] = 'db/warehouse/schema.rb'
    # set config variables for custom database
    new_config.each do |path, value|
      Rails.application.config.paths[path] = value
    end
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  end

  def self.needs_migration?
    # integers from file list
    (ActiveRecord::MigrationContext.new('db/warehouse/migrate').migrations.collect(&:version) - GrdaWarehouse::SchemaMigration.pluck(:version).map(&:to_i)).any?
  end
end
