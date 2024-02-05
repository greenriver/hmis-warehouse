###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == AppResourceMonitor::PostgresInspector
#
# Utility to help monitor health and growth of postgres database
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
      pg_database_size(%{db_name})::bigint AS total_size
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
      %{db_name} AS database,
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
