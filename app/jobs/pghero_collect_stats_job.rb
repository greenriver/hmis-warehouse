###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class PgheroCollectStatsJob < ::BaseJob
  def perform(clean: false)
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

  def with_lock(&block)
    lock_name = self.class.name.to_s
    GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
  end
end
