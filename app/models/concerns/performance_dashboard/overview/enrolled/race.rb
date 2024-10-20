###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled::Race
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def enrolled_by_race
    @enrolled_by_race ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: PerformanceDashboards::Overview::EXPIRATION_LENGTH) do
      buckets = race_buckets.map { |b| [b, []] }.to_h
      counted = {}
      enrolled.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, :first_date_in_program, *race_columns).
        each do |id, _, *cols|
          races = race_columns.zip(cols).to_h
          bucket = race_bucket(races)
          counted[bucket] ||= Set.new
          buckets[bucket] << id unless counted[bucket].include?(id)
          counted[bucket] << id
        end
      buckets
    end
  end

  private def race_columns
    [
      :AmIndAKNative,
      :Asian,
      :BlackAfAmerican,
      :NativeHIPacific,
      :White,
      :HispanicLatinaeo,
      :MidEastNAfrican,
      :RaceNone,
    ].freeze
  end

  def enrolled_by_race_data_for_chart
    @enrolled_by_race_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += enrolled_by_race.values.map(&:count)
      categories = enrolled_by_race.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HudUtility2024.race(s)] }.to_h,
          chosen: @races,
          columns: columns,
          categories: categories.map { |s| race_title(s) },
        },
      )
    end
  end

  private def enrolled_by_race_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      enrolled_by_race[sub_key.to_s]
    else
      enrolled_by_race.values.flatten
    end
    details = enrolled.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
