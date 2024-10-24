###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == AppResourceMonitor::PostgresInspector
#
# Utility to help monitor health and growth of postgres database
#
# Note, we cast floats to text to prevent ruby from using scientific notation
#
class AppResourceMonitor::PostgresInspector
  extend Enumerable
  include SafeInspectable
  delegate :select_all, :quote, to: :connection

  attr_accessor :connection

  def initialize(connection:)
    self.connection = connection
  end

  def self.each
    seen = Set.new
    ActiveRecord::Base.descendants.each do |klass|
      adapter = begin
        klass.connection_db_config.adapter
      rescue ActiveRecord::ConnectionNotEstablished
        Rails.logger.info("Skipping #{klass} not connected")
      end
      next unless  adapter.to_s =~ /\A(postgresql|postgis)\z/

      connection = klass.connection
      next if connection.current_database.in?(seen)

      seen << connection.current_database
      yield new(connection: connection)
    end
  end

  def table_stats
    select_all(format(TABLE_STATS_SQL, query_variables))
  end

  def index_stats
    select_all(format(INDEX_STATS_SQL, query_variables))
  end

  def database_stats
    select_all(format(DATABASE_STATS_SQL, query_variables))
  end

  def toast_stats
    select_all(format(TOAST_STATS_SQL, query_variables))
  end

  def query_variables
    db_name = connection.current_database
    {
      db_name: quote(db_name),
      schema: quote('public'),
    }
  end

  DATABASE_STATS_SQL = <<~SQL.freeze
    SELECT
      %{db_name} AS database,
      pg_database_size(%{db_name})::text AS total_size
    FROM
      pg_stat_database
    WHERE
      datname = %{db_name}
  SQL

  TABLE_STATS_SQL = <<~SQL.freeze
    SELECT
      %{db_name} AS database,
      t.tablename,
      c.reltuples::bigint AS num_rows,
      pg_relation_size(quote_ident(t.tablename)::text)::text AS table_size,
      pg_indexes_size(quote_ident(t.tablename)::text)::text AS index_size,
      n_live_tup::text AS live_tuples,
      n_dead_tup::text AS dead_tuples,
      CASE WHEN n_live_tup = 0 THEN '0' ELSE (n_dead_tup::float / n_live_tup)::text END AS dead_tuple_ratio,
      GREATEST(stat.last_vacuum, stat.last_autovacuum) AS last_vacuum,
      GREATEST(stat.last_analyze, stat.last_autoanalyze) AS last_analyze
    FROM
      pg_tables t
    LEFT OUTER JOIN
      pg_class c ON t.tablename = c.relname
    LEFT OUTER JOIN
      pg_stat_user_tables stat ON t.tablename = stat.relname AND t.schemaname = stat.schemaname
    WHERE
      t.schemaname = %{schema}
    ORDER BY
      t.tablename;
  SQL

  TOAST_STATS_SQL = <<~SQL.freeze
    SELECT
      %{db_name} AS database,
      relname AS table_name,
      pg_total_relation_size(reltoastrelid)::text AS toast_table_size
    FROM
      pg_class c
    JOIN
      pg_namespace n ON c.relnamespace = n.oid
    WHERE
      nspname = %{schema} AND
      reltoastrelid != 0
    ORDER BY
      table_name;
  SQL

  INDEX_STATS_SQL = <<~SQL.freeze
    SELECT
      %{db_name} AS database,
      c.relname AS tablename,
      ipg.relname AS index_name,
      psai.idx_scan::text AS number_of_scans,
      psai.idx_tup_read::text AS tuples_read,
      psai.idx_tup_fetch::text AS tuples_fetched,
      pg_relation_size(ipg.oid)::text AS index_size,
      pg_get_indexdef(x.indexrelid) AS index_definition,
      0 <> ALL (x.indkey) AS has_expression_index_column,
      x.indisunique AS is_unique_index,
      EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint con
        WHERE con.conindid = x.indexrelid
      ) AS enforces_constraint
      FROM
        pg_class c
      JOIN
        pg_index x ON x.indrelid = c.oid
      JOIN
        pg_class ipg ON ipg.oid = x.indexrelid
      JOIN
        pg_stat_user_indexes psai ON x.indexrelid = psai.indexrelid
      JOIN
        pg_namespace n ON n.oid = c.relnamespace
      WHERE
        n.nspname = %{schema}
        AND c.relkind = 'r'  -- Only include tables, not views or other relations
      ORDER BY
        c.relname, ipg.relname;
  SQL
end
