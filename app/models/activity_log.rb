###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ActivityLog < ApplicationRecord
  include ArelHelper

  belongs_to :user

  # `path` is request.fullpath (path + query string), which is otherwise unbounded and can exceed
  # Postgres's btree index row limit. `path` also serves as an unmodified audit trail elsewhere, so
  # it can't be truncated or excluded from anything itself; report-usage matching instead uses
  # `reporting_path`, an always-short mirror kept in sync by the before_save callback below (and
  # backfilled for existing rows in db/migrate/20260827150000_add_reporting_path_to_activity_logs.rb).
  # Report urls are always far shorter than this, so no report-matching condition is affected by it.
  REPORTING_PATH_LENGTH = 200

  # The client a request was about, taken from the first `/clients/<id>` segment of the path
  # (query string excluded). The leading `/` keeps `/source_clients/<id>` out; the trailing
  # boundary keeps `/clients/1010` from matching client 101; the 18-digit cap keeps a bogus id
  # from overflowing bigint and failing the save. CLIENT_PATH_SQL_PATTERN must stay equivalent:
  # it backfills rows written before this column existed.
  CLIENT_PATH_PATTERN = /\/clients\/(\d{1,18})(?:[\/.]|\z)/
  CLIENT_PATH_SQL_PATTERN = '/clients/([0-9]{1,18})(?:[/.]|$)'
  CLIENT_ID_INDEX_NAME = 'index_activity_logs_on_client_id_and_created_at'

  before_save :set_reporting_path, :set_client_id

  # `range` is a Date..Date; created_at is stored as a UTC instant, so comparing it against bare
  # date literals drops rows created in the evening (US Eastern), whose UTC-stored date has already
  # rolled to the next day.
  scope :created_in_range, ->(range:) do
    where(created_at: range.begin.beginning_of_day..range.end.end_of_day)
  end

  scope :warehouse_reports, -> do
    where(warehouse_report_conditions.map(&:last).reduce(:or))
  end

  # [url, arel condition] per ReportDefinition.report_list entry. Each report's condition
  # defaults to a path-prefix match, but can be overridden via a `reporting_query` lambda on the
  # report_list entry (see the Nightly Census entry in report_definition.rb, whose date_range/
  # details sub-routes are also hit by a widget embedded on other pages, so a bare path match
  # would over-count). Shared by the `warehouse_reports` scope above and by
  # AccessLogs::WarehouseReports::UsageSummary, which needs the same per-report conditions
  # individually (not just OR'd together) to attribute each row to a report.
  def self.warehouse_report_conditions
    GrdaWarehouse::WarehouseReports::ReportDefinition.report_list.values.flatten.map do |r|
      [r[:url], r[:reporting_query]&.call(arel_table) || default_report_condition(r[:url])]
    end
  end

  # Exact match, or the url followed by a `/` (a nested path) or `?` (a query string) -- not a
  # bare `LIKE '/url%'`, which would also match a sibling report whose url happens to be a
  # string-prefix of this one (e.g. 'warehouse_reports/chronic' matching
  # 'warehouse_reports/chronic_housed' traffic too, misattributing it via first-match-wins).
  def self.default_report_condition(url)
    at = arel_table
    at[:reporting_path].eq("/#{url}").or(at[:reporting_path].matches("/#{url}/%")).or(at[:reporting_path].matches("/#{url}?%"))
  end

  def clean_object_name
    item_model&.gsub('GrdaWarehouse::Hud::', '')
  end

  CLIENT_PATH_ID = /(?:\A|\/)clients\/(\d+)(?:[\/?]|\z)/

  # item_id holds the nested resource's id on pages like clients/:client_id/files/:id, so the
  # client id comes from the path.
  # @return [Integer, nil]
  def client_id_from_path
    return unless item_model == 'GrdaWarehouse::Hud::Client'

    path&.match(CLIENT_PATH_ID)&.[](1)&.to_i
  end

  # Client page titles are stored at visit time as "<name>" or "<name> - <page>", so a row logged
  # before the client was restricted still carries the client's name.
  # @param name_redacted [Boolean]
  def display_title(name_redacted: false)
    return title || controller_name unless title && name_redacted

    redacted = GrdaWarehouse::PiiProvider::NAME_REDACTED
    return redacted unless title.include?(' - ')

    "#{redacted} - #{title.rpartition(' - ').last}"
  end

  # Backfills reporting_path for rows that predate it (see
  # db/migrate/20260827150000_add_reporting_path_to_activity_logs.rb); run out of band via
  # TaskQueue rather than in that migration, since activity_logs is too large to backfill within a
  # deployment's migration window.
  def self.backfill_reporting_path!(batch_size: 1000)
    loop do
      updated = where(reporting_path: nil).
        where.not(path: nil).
        limit(batch_size).
        update_all(reporting_path: Arel.sql("left(path, #{REPORTING_PATH_LENGTH})"))
      break if updated.zero?
    end
  end

  # Sets client_id for rows that predate it, in id ranges so each batch is a bounded index range
  # scan; run out of band via TaskQueue. Rows that don't match stay nil and aren't rewritten.
  def self.backfill_client_id!(batch_size: 10_000)
    batch_start = minimum(:id)
    return unless batch_start

    # Named binds: a literal '?' in the SQL would be read as a positional placeholder.
    binds = { separator: '?', pattern: CLIENT_PATH_SQL_PATTERN }
    # maximum is re-read each batch: during a rolling deploy, pods still on old code keep writing
    # rows without client_id, and those land past whatever the max was when the backfill started.
    while batch_start <= maximum(:id)
      where(id: batch_start...(batch_start + batch_size), client_id: nil).
        where('split_part(path, :separator, 1) ~ :pattern', binds).
        update_all(['client_id = substring(split_part(path, :separator, 1) from :pattern)::bigint', binds])
      batch_start += batch_size
    end
  end

  # Built from TaskQueue rather than a migration: activity_logs is written on every request, and
  # a concurrent build inside a migration can fail to get its lock. Idempotent:
  # If the index exists and is valid, do nothing
  # If the index is invalid (a failed concurrent build), drop it and rebuild it
  # If the index does not exist, create it
  def self.ensure_client_id_index!
    valid = connection.select_value(<<~SQL)
      SELECT i.indisvalid FROM pg_index i JOIN pg_class c ON c.oid = i.indexrelid WHERE c.relname = #{connection.quote(CLIENT_ID_INDEX_NAME)}
    SQL
    return if valid == true

    connection.remove_index(table_name, name: CLIENT_ID_INDEX_NAME, algorithm: :concurrently) if valid == false
    connection.add_index(
      table_name,
      [:client_id, :created_at],
      name: CLIENT_ID_INDEX_NAME,
      where: 'client_id IS NOT NULL',
      algorithm: :concurrently,
    )
  end

  # increment can be: minute, hour, day, week, month, year
  def self.for_chart(increment: 'hour', range: 1.weeks.ago..Time.current)
    return [] unless valid_increments.include?(increment)

    data = {}
    where(created_at: range).
      group(:created_at_trunc, :user_id).
      pluck(Arel.sql("date_trunc('#{increment}', created_at) as created_at_trunc"), :user_id).
      each do |time, _user_id|
        data[time.strftime('%Y-%m-%d %H:%M')] ||= 0
        data[time.strftime('%Y-%m-%d %H:%M')] += 1
      end
    [
      ['x'] + data.keys,
      ['Active Users'] + data.values,
    ]
  end

  def self.valid_increments
    ['minute', 'hour', 'day', 'week', 'month', 'year']
  end

  # Spreadsheet rows for the User Access Logs export: the header, then one row per log, streamed
  # in batches so the caller never holds the whole table in memory.
  def self.export_rows(user_id: nil, range: 1.years.ago..Time.current, limit: nil)
    columns = {
      user_id: 'User ID',
      agency_name_column => 'Agency Name',
      path: 'Path',
      created_at: 'Access Time',
      session_hash: 'Session',
      ip_address: 'IP Address',
      referrer: 'Referrer',
    }
    scope = where(created_at: range).left_outer_joins(user: :agency)
    scope = scope.where(user_id: user_id) if user_id.present?
    scope = scope.limit(limit) if limit
    Enumerator.new do |rows|
      rows << columns.values
      scope.in_batches do |batch|
        scrub(pluck_to_hash(columns, batch)).each { |row| rows << row.values }
      end
    end
  end

  def self.agency_name_column
    Agency.arel_table[:name]
  end

  def self.scrub(data)
    report_replacements = GrdaWarehouse::WarehouseReports::ReportDefinition.pluck(:id, :name)
    data.map do |row|
      # Strip anything after the ?
      row[:path] = row[:path]&.gsub(/\?.*/, '')
      row[:referrer] = row[:referrer]&.gsub(/\?.*/, '')
      row[:created_at] = row[:created_at].to_fs(:db)
      cleanup_report_paths(row, report_replacements)
    end
  end

  def self.pluck_to_hash(columns, scope)
    scope.pluck(*columns.keys).map do |row|
      Hash[columns.keys.zip(row)]
    end
  end

  def self.cleanup_report_paths(row, report_replacements)
    return row unless row[:path].starts_with?('/reports/')

    report_replacements.each do |id, name|
      row[:path] = row[:path].sub("/reports/#{id}/", "/reports/#{name.parameterize}/")
    end
    row
  end

  private def set_reporting_path
    self.reporting_path = path&.first(REPORTING_PATH_LENGTH)
  end

  private def set_client_id
    self.client_id = path&.split('?', 2)&.first&.match(CLIENT_PATH_PATTERN)&.[](1)&.to_i
  end
end
