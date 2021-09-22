###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Race
  extend ActiveSupport::Concern

  private def race_buckets
    HUD.races.keys + ['Multiple', 'Unknown']
  end

  def race_title(key)
    return 'Multi-Race' if key == 'Multiple'
    return 'Unknown-Race' if key == 'Unknown'

    HUD.race(key)
  end

  def race_bucket_titles
    race_buckets.map do |key|
      [
        key,
        race_title(key),
      ]
    end.to_h
  end

  def race_bucket(am_ind_ak_native, asian, black_af_american, native_hi_other_pacific, white, race_none)
    races = []
    races << 'AmIndAKNative' if am_ind_ak_native == 1
    races << 'Asian' if asian == 1
    races << 'BlackAfAmerican' if black_af_american == 1
    races << 'NativeHIPacific' if native_hi_other_pacific == 1
    races << 'White' if white == 1
    races << 'RaceNone' if race_none == 1
    return 'Unknown' if races.empty?
    return races.first if races.count == 1

    'Multiple'
  end
end
