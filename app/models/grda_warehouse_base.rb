###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    skip = options.fetch(:skip, [:lock_version])
    super(options.merge(versions: versions, skip: skip))
  end

  # allows delegation of paper trail metadata
  # replicate paper_trail model_metadatum (mostly)
  # @param key [Symbol]
  def paper_trail_meta_value(key)
    meta = self.class.paper_trail_options&.fetch(:meta)
    value = meta ? meta[key] : nil
    return unless value

    if value.respond_to?(:call)
      value.call(self)
    elsif value.is_a?(Symbol) && respond_to?(value, true)
      send(value)
    else
      value
    end
  end

  def self.references_hud_client?
    columns_hash.key?('PersonalID') && !!reflect_on_association(:client)
  end

  def self.references_hud_enrollment?
    columns_hash.key?('EnrollmentID') && !!reflect_on_association(:enrollment)
  end

  def self.references_hud_project?
    columns_hash.key?('ProjectID') && !!reflect_on_association(:project)
  end
end
