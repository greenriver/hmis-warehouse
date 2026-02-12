###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Note, only pks in the dev/test env are updated. The assumption is that production instances are
# already corrected and we are aligning our dev dbs.
#
# Note, we skip partitioned tables and will handle those in dedicated migrations later
class StandardizeIdsToBigint < ActiveRecord::Migration[7.2]
  def up
    return unless Rails.env.development? || Rails.env.test?

    # extra safety check
    db_name = ActiveRecord::Base.connection.current_database
    raise "database \"#{db_name}\" not supported" unless db_name =~ /(development|test)/

    views = ['puma_scaling_login_demand']
    views.reverse_each { |view| drop_view view }
    alter_tables
    views.each { |view| create_view view }
  end

  private def alter_tables
    # This query identifies integer columns that should be bigints
    query = <<~SQL
      SELECT
        col.table_schema,
        col.table_name,
        col.column_name
      FROM information_schema.columns col
      JOIN information_schema.tables tab ON (
        tab.table_schema = col.table_schema
        AND tab.table_name = col.table_name
        AND tab.table_catalog = col.table_catalog
      )
      WHERE col.table_catalog = current_database()
        AND data_type = 'integer'
        AND col.table_schema != 'pg_catalog'
        AND col.table_schema != 'information_schema'
        AND (column_name ~ '(^|_)id$' or column_name ~ '(^|_)from$' or column_name ~ '(^|_)into$')
        AND SUBSTRING(column_name FROM 1 FOR 1) = LOWER(SUBSTRING(column_name FROM 1 FOR 1))
        AND column_name !~ 'override'
        AND tab.table_type != 'VIEW'
        AND col.table_name NOT IN (
          SELECT c.relname AS child
          FROM pg_inherits
          JOIN pg_class AS c ON (inhrelid=c.oid)
          JOIN pg_class as p ON (inhparent=p.oid)
        )
      ORDER BY col.table_name asc, column_name asc;
    SQL

    results = safely_execute(query)
    results.each do |row|
      schema = row['table_schema']
      table = row['table_name']
      column = row['column_name']
      next if partitioned?(table: table, schema: schema)

      # We need to quote table and column names because some warehouse tables
      # use CamelCase (e.g. "AssessmentQuestions")
      safely_execute "ALTER TABLE \"#{schema}\".\"#{table}\" ALTER COLUMN \"#{column}\" TYPE bigint;"
    end
  end

  private def partitioned?(table:, schema: 'public')
    result = safely_execute("SELECT c.relkind FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = '#{schema}' AND c.relname = '#{table}'")
    result && result[0]['relkind'] == 'p'
  end

  private def safely_execute(statement)
    safety_assured { execute(statement) }
  end
end
