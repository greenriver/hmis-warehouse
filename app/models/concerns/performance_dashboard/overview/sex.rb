###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceDashboard::Overview::Sex
  extend ActiveSupport::Concern

  private def sex_buckets
    HudHelper.util.sexes.keys
  end

  def sex_bucket_titles
    sex_buckets.map do |key|
      [
        key,
        HudHelper.util.sex(key),
      ]
    end.to_h
  end

  def sex_bucket(sex)
    return 99 unless sex

    sex
  end

  def sex_query(key)
    return '0=1' unless key

    c_t[:Sex].eq(key.to_i)
  end
end
