###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PgheroCollectStatsJob < ::BaseJob
  def perform(clean: false)
    # seems to break on pg12
    return unless postgres_version >= 13
    return unless stats_reset_defined? && stats_reset_allowed?
    return unless PgHero.query_stats_enabled?

    with_lock do
      PgHero.capture_space_stats
      PgHero.capture_query_stats

      if clean
        # prunes old stats, keeps these tables from growing
        PgHero.clean_query_stats
        PgHero.clean_space_stats
      end
    end
  end

  protected

  def connection
    GrdaWarehouseBase.connection
  end

  def postgres_version
    sql = 'SELECT version()'
    str = connection.select_value(sql).presence
    return unless str

    str.gsub(/^PostgreSQL (\d*)\..*/, '\1').to_i
  end

  # do we have permission to run?
  def stats_reset_allowed?
    sql = "SELECT has_function_privilege(current_user, 'pg_stat_statements_reset(Oid, Oid, bigint)', 'EXECUTE')"
    connection.select_value(sql).present?
  end

  def stats_reset_defined?
    sql = "select pg_get_functiondef(oid) from pg_proc where proname = 'pg_stat_statements_reset'"
    connection.select_value(sql).present?
  end

  def with_lock(&block)
    lock_name = self.class.name.to_s
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end
end
