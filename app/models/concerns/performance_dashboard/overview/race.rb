###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Race
  extend ActiveSupport::Concern

  private def race_buckets
    HudUtility2024.races.keys + ['Multiple'] - ['HispanicLatinaeo']
  end

  def race_title(key)
    return 'Multiple' if key == 'Multiple'

    HudUtility2024.race(key)
  end

  def race_bucket_titles
    race_buckets.map do |key|
      [
        key,
        race_title(key),
      ]
    end.to_h
  end

  def race_bucket(client_races)
    races = []
    races << 'AmIndAKNative' if client_races[:AmIndAKNative] == 1
    races << 'Asian' if client_races[:Asian] == 1
    races << 'BlackAfAmerican' if client_races[:BlackAfAmerican] == 1
    races << 'NativeHIPacific' if client_races[:NativeHIPacific] == 1
    races << 'White' if client_races[:White] == 1
    races << 'MidEastNAfrican' if client_races[:MidEastNAfrican] == 1
    return 'RaceNone' if client_races[:RaceNone].in?([8, 9, 99]) || races.empty?
    return races.first if races.count == 1

    'Multiple'
  end
end
