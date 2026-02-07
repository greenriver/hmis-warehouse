###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class StandardizeIdsToBigint < ActiveRecord::Migration[7.2]
  def up
    views = [
      'puma_scaling_login_demand',
    ]
    views.each { |view| drop_view view }
    safety_assured { _up }
    views.each { |view| create_view view }
  end

  def _up
    # This query identifies integer columns that should be bigints,
    # based on naming conventions and common sense exclusions.
    # It is derived from issue.sql and handles cases where the type
    # might already have been changed in some environments.
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
        AND (column_name ~ 'id' or column_name ~ 'from' or column_name ~ 'into')
        AND SUBSTRING(column_name FROM 1 FOR 1) = LOWER(SUBSTRING(column_name FROM 1 FOR 1))
        AND column_name !~ 'override'
        AND tab.table_type != 'VIEW'
        AND col.table_name NOT IN (
          SELECT c.relname AS child
          FROM pg_inherits
          JOIN pg_class AS c ON (inhrelid=c.oid)
          JOIN pg_class as p ON (inhparent=p.oid)
        )
        AND col.table_name || '.' || col.column_name NOT IN (
          'warehouse_houseds.differentidentity',
          'warehouse_partitioned_monthly_reports.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports.project_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.client_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.destination_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.enrollment_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.organization_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_adult_only_households.project_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.client_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.destination_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.enrollment_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.organization_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_adults_with_children.project_id',
          'warehouse_partitioned_monthly_reports_child_only_households.client_id',
          'warehouse_partitioned_monthly_reports_child_only_households.destination_id',
          'warehouse_partitioned_monthly_reports_child_only_households.enrollment_id',
          'warehouse_partitioned_monthly_reports_child_only_households.organization_id',
          'warehouse_partitioned_monthly_reports_child_only_households.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_child_only_households.project_id',
          'warehouse_partitioned_monthly_reports_clients.client_id',
          'warehouse_partitioned_monthly_reports_clients.destination_id',
          'warehouse_partitioned_monthly_reports_clients.enrollment_id',
          'warehouse_partitioned_monthly_reports_clients.organization_id',
          'warehouse_partitioned_monthly_reports_clients.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_clients.project_id',
          'warehouse_partitioned_monthly_reports_non_veterans.client_id',
          'warehouse_partitioned_monthly_reports_non_veterans.destination_id',
          'warehouse_partitioned_monthly_reports_non_veterans.enrollment_id',
          'warehouse_partitioned_monthly_reports_non_veterans.organization_id',
          'warehouse_partitioned_monthly_reports_non_veterans.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_non_veterans.project_id',
          'warehouse_partitioned_monthly_reports_unknown.client_id',
          'warehouse_partitioned_monthly_reports_unknown.destination_id',
          'warehouse_partitioned_monthly_reports_unknown.enrollment_id',
          'warehouse_partitioned_monthly_reports_unknown.organization_id',
          'warehouse_partitioned_monthly_reports_unknown.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_unknown.project_id',
          'warehouse_partitioned_monthly_reports_veterans.client_id',
          'warehouse_partitioned_monthly_reports_veterans.destination_id',
          'warehouse_partitioned_monthly_reports_veterans.enrollment_id',
          'warehouse_partitioned_monthly_reports_veterans.organization_id',
          'warehouse_partitioned_monthly_reports_veterans.prior_exit_destination_id',
          'warehouse_partitioned_monthly_reports_veterans.project_id',
          'warehouse_returns.client_id',
          'warehouse_returns.differentidentity'
        )
      ORDER BY col.table_name asc, column_name asc;
    SQL

    results = execute(query)
    results.each do |row|
      schema = row['table_schema']
      table = row['table_name']
      column = row['column_name']

      # We need to quote table and column names because some tables
      # may use CamelCase or other non-standard naming.
      execute "ALTER TABLE \"#{schema}\".\"#{table}\" ALTER COLUMN \"#{column}\" TYPE bigint;"
    end
  end

  def down
    # No-op: we don't want to revert bigints to integers.
  end
end
