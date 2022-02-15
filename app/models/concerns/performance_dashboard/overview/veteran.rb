###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Veteran
  extend ActiveSupport::Concern

  private def veteran_buckets
    HUD.no_yes_reasons_for_missing_data_options.keys
  end

  def veteran_bucket_titles
    veteran_buckets.map do |key|
      [
        key,
        HUD.veteran_status(key),
      ]
    end.to_h
  end

  def veteran_bucket(veteran_status)
    return 99 unless veteran_status

    veteran_status
  end

  def veteran_query(key)
    return '0=1' unless key

    c_t[:VeteranStatus].eq(key.to_i)
  end
end
