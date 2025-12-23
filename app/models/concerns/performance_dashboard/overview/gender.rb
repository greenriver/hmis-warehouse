###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceDashboard::Overview::Gender
  extend ActiveSupport::Concern

  private def gender_buckets
    HudHelper.util.genders.keys
  end

  def gender_bucket_titles
    gender_buckets.map do |key|
      [
        key,
        HudHelper.util.gender(key),
      ]
    end.to_h
  end

  def gender_bucket(gender)
    return 99 unless gender

    gender
  end

  def gender_query(key)
    return '0=1' unless key

    c_t[HudHelper.util.gender_id_to_field_name[key.to_i].to_sym].eq(HudHelper.util.gender_comparison_value(key))
  end
end
