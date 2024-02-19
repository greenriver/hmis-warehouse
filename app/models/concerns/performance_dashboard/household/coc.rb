###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Coc
  extend ActiveSupport::Concern

  private def coc_buckets
    GrdaWarehouse::Hud::ProjectCoc.distinct.
      joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user, permission: :can_view_assigned_reports)).
      pluck(:CoCCode)
  end

  def coc_bucket_titles
    coc_buckets.map do |key|
      [
        key,
        HudUtility2024.coc_name(key),
      ]
    end.to_h
  end

  def coc_bucket(coc)
    coc
  end

  def coc_query(key)
    return '0=1' unless key

    ec_t[:CoCCode].eq(key.to_s)
  end
end
