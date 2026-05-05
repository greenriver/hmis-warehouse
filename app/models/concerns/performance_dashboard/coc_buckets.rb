###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceDashboard::CocBuckets
  extend ActiveSupport::Concern

  private def coc_buckets
    GrdaWarehouse::Hud::ProjectCoc.distinct.
      joins(:project).
      merge(GrdaWarehouse::Hud::Project.viewable_by(@filter.user, permission: :can_view_assigned_reports)).
      pluck(:CoCCode).compact
  end

  # Hide CoCs when value is 0 and the CoC is not in known CoCs (Lookups::CocCode)
  def filter_coc_buckets_for_display(buckets)
    known = known_coc_codes
    buckets.select { |key, ids| ids.any? || known.include?(key) }
  end

  def coc_data_for_chart(buckets)
    filtered = filter_coc_buckets_for_display(buckets)
    columns = [@filter.date_range_words]
    columns += filtered.values.map(&:count)
    categories = filtered.keys
    filter_selected_data_for_chart(
      {
        labels: categories.map { |s| [s, HudHelper.util.coc_name(s)] }.to_h,
        chosen: @coc_codes,
        columns: columns,
        categories: categories,
      },
    )
  end

  private def known_coc_codes
    GrdaWarehouse::Lookups::CocCode.
      viewable_by(@filter.user, permission: :can_view_assigned_reports).
      pluck(:coc_code)
  end

  def coc_bucket_titles
    result = coc_buckets.map do |key|
      [
        key,
        HudHelper.util.coc_name(key),
      ]
    end.to_h
    result['Data not collected'] = 'Data not collected'
    result
  end

  def coc_bucket(coc)
    coc.presence || 'Data not collected'
  end

  def coc_query(key)
    return '0=1' unless key.present?
    return e_t[:enrollment_coc].eq(nil).or(e_t[:enrollment_coc].eq('')) if key.to_s == 'Data not collected'

    e_t[:enrollment_coc].eq(key.to_s)
  end
end
