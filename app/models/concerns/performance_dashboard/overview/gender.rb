###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Gender
  extend ActiveSupport::Concern

  private def gender_buckets
    HUD.genders.keys
  end

  def gender_bucket_titles
    gender_buckets.map do |key|
      [
        key,
        HUD.gender(key),
      ]
    end.to_h
  end

  def gender_bucket(gender)
    return 99 unless gender

    gender
  end

  def gender_query(key)
    return '0=1' unless key

    c_t[HUD.gender_id_to_field_name[key.to_i].to_sym].eq(HUD.gender_comparison_value(key))
  end
end
