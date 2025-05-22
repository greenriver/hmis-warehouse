###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Dba::PartitionAll
  def tables
    t = {}
    loader_table_classes.each do |klass|
      t[klass] = klass.table_name
    end
    importer_table_classes.each do |klass|
      t[klass] = klass.table_name
    end
    t.reject! do |_klass, x|
      x.match?(/exports|organizations|projects|funders|inventories|project_cocs|affiliations|users/)
    end
    t.sort
  end

  def space_needed(base_class = GrdaWarehouseBase)
    table_names = tables.values.map { |t| "'#{t}'" }.join(', ')

    # Finished tables won't be included as the relkind is different (p)
    r = base_class.connection.execute(<<~SQL)
      WITH sizes AS (
        SELECT
          n.nspname AS "schema",
          c.relname AS name,
          pg_total_relation_size(c.oid) AS index_and_table_size
        FROM
          pg_class c
          LEFT JOIN pg_namespace n ON (n.oid = c.relnamespace)
        WHERE
          n.nspname NOT IN ('pg_catalog', 'information_schema')
          AND n.nspname !~ '^pg_toast'
          AND c.relkind IN ('r', 'm')
          AND c.relname IN (#{table_names})
      )
      SELECT pg_size_pretty(sum(index_and_table_size)) as needed_space
      FROM sizes
    SQL
    Rails.logger.info "We need #{r.to_a[0]['needed_space']} to partition everything"
  end

  # 6716 partitions.
  def run!
    Rails.logger.warn "Making #{71 * tables.length} partitions"

    tables.each_value do |table|
      Rails.logger.info "==== Partitioning #{table} ===="
      pm = Dba::PartitionMaker.new(table_name: table)
      if pm.no_table?
        Rails.logger.error "Skipping #{table} which couldn't be found"
      elsif pm.done?
        Rails.logger.info "Skipping #{table} which is done"
        next
      else
        pm.run!
      end
    end
  end

  # Use this with great care
  def remove_saved_tables!
    raise 'Aborting. You must set DELETE_THEM=true in your environment' unless ENV['DELETE_THEM'] == 'true'

    tables.each_value do |table|
      GrdaWarehouseBase.connection.execute(<<~SQL)
        DROP TABLE IF EXSITS "#{table}_saved"
      SQL
    end
  end
end
