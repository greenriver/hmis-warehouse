###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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

  # def self.reset_connection
  #   self.connection.disconnect!
  #   self.establish_connection DB_WAREHOUSE
  # end

  # def self.setup_config
  #   new_config = {
  #     'db' => ['db/warehouse'],
  #     'db/migrate' => ['db/warehouse/migrate'],
  #     'db/seeds' => ['db/warehouse/seeds'],
  #     'config/database' => ['config/database_warehouse.yml'],
  #   }
  #   ENV['SCHEMA'] = 'db/warehouse/schema.rb'
  #   # set config variables for custom database
  #   new_config.each do |path, value|
  #     Rails.application.config.paths[path] = value
  #   end
  #   db_config = Rails.application.config.paths['config/database'].to_a.first
  #   ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  # end

  def self.needs_migration?
    ActiveRecord::MigrationContext.new('db/warehouse/migrate', GrdaWarehouse::SchemaMigration).needs_migration?
  end
end
