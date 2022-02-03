###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Ethnicity
  extend ActiveSupport::Concern

  private def ethnicity_buckets
    HUD.ethnicities.keys
  end

  def ethnicity_bucket_titles
    ethnicity_buckets.map do |key|
      [
        key,
        HUD.ethnicity(key),
      ]
    end.to_h
  end

  def ethnicity_bucket(ethnicity)
    return 99 unless ethnicity.present?

    ethnicity
  end

  def ethnicity_query(key)
    return '0=1' unless key.present?

    c_t[:Ethnicity].eq(key.to_i)
  end
end
