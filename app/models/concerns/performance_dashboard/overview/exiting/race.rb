###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting::Race
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_race
    @exiting_by_race ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = race_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, :AmIndAKNative, :Asian, :BlackAfAmerican, :NativeHIPacific, :White, :RaceNone, :first_date_in_program).each do |id, am_ind_ak_native, asian, black_af_american, native_hi_pacific, white, race_none, _|
          counted[race_bucket(am_ind_ak_native, asian, black_af_american, native_hi_pacific, white, race_none)] ||= Set.new
          buckets[race_bucket(am_ind_ak_native, asian, black_af_american, native_hi_pacific, white, race_none)] << id unless counted[race_bucket(am_ind_ak_native, asian, black_af_american, native_hi_pacific, white, race_none)].include?(id)
          counted[race_bucket(am_ind_ak_native, asian, black_af_american, native_hi_pacific, white, race_none)] << id
        end
      buckets
    end
  end

  def exiting_by_race_data_for_chart
    @exiting_by_race_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_race.values.map(&:count)
      categories = exiting_by_race.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HUD.race(s)] }.to_h,
          chosen: @races,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def exiting_by_race_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      exiting_by_race[sub_key.to_s]
    else
      exiting_by_race.values.flatten
    end
    details = exiting.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
