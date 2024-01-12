###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == GrdaWarehouse::PostgresInspector
#
# Utility to help monitor health and growth of postgres database
#
class GrdaWarehouse::PostgresInspector
  include SafeInspectable
  delegate :select_all, :quote, to: :connection

  attr_accessor :name, :connection

  def initialize(name:, connection:)
    self.name = name
    self.connection = connection
  end

  def self.inspect_each
    configs = Rails.configuration.database_configuration[Rails.env]

    configs.each_pair do |name, config|
      next unless config['adapter'] == 'postgresql'

      connection = ActiveRecord::Base.establish_connection(config).connection
      yield new(name: name, connection: connection)
    end
    nil
  end

  def table_stats(schema: 'public')
    select_all(format(TABLE_STATS_SQL, schema: quote(schema)))
  end

  def index_stats(schema: 'public')
    select_all(format(INDEX_STATS_SQL, schema: quote(schema)))
  end

  def database_stats
    db_name = connection.current_database
    select_all(format(DATABASE_STATS_SQL, db_name: quote(db_name)))
  end

  DATABASE_STATS_SQL = <<~SQL.freeze
    SELECT
      pg_database_size(%{db_name})::bigint AS total_size,
      CASE
        WHEN (blks_hit + blks_read) = 0 THEN 0.0
        ELSE round((blks_hit / (blks_hit + blks_read)::float)::numeric, 2)::float
      END AS cache_hit_ratio,
      temp_bytes,
      deadlocks,
      stats_reset
    FROM
      pg_stat_database
    WHERE
      datname = %{db_name}
  SQL

  TABLE_STATS_SQL = <<~SQL.freeze
    SELECT
      t.tablename,
      c.reltuples::bigint AS num_rows,
      pg_relation_size(quote_ident(t.tablename)::text) AS table_size,
      pg_indexes_size(quote_ident(t.tablename)::text) AS index_size
    FROM
      pg_tables t
    LEFT OUTER JOIN
      pg_class c ON t.tablename = c.relname
    WHERE
      t.schemaname = %{schema}
    ORDER BY
      t.tablename;
  SQL

  INDEX_STATS_SQL = <<~SQL.freeze
    SELECT
      t.tablename,
      ipg.relname AS index_name,
      idx_scan AS number_of_scans,
      idx_tup_read AS tuples_read,
      idx_tup_fetch AS tuples_fetched,
      pg_relation_size(ipg.oid) AS index_size
    FROM
      pg_tables t
    JOIN
      pg_index x ON x.indrelid = (SELECT oid FROM pg_class WHERE relname = t.tablename)
    JOIN
      pg_class ipg ON ipg.oid = x.indexrelid
    JOIN
      pg_stat_all_indexes psai ON x.indexrelid = psai.indexrelid
    WHERE
      t.schemaname = %{schema}
    ORDER BY
      t.tablename, ipg.relname;
  SQL
end
