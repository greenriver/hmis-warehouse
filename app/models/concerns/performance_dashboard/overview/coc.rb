# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Coc
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
    coc.presence || 'N/A'
  end

  def coc_query(key)
    return '0=1' unless key.present?

    e_t[:enrollment_coc].eq(key.to_s)
  end
end
