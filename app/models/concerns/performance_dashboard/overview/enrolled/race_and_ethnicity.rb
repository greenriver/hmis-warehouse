###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled::RaceAndEthnicity
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def enrolled_by_race_and_ethnicity
    @enrolled_by_race_and_ethnicity ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: PerformanceDashboards::Overview::EXPIRATION_LENGTH) do
      buckets = race_and_ethnicity_buckets.map { |b| [b, []] }.to_h
      counted = {}
      enrolled.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, :first_date_in_program, *race_and_ethnicity_columns).
        each do |id, _, *cols|
          race_and_ethnicities = race_and_ethnicity_columns.zip(cols).to_h
          bucket = race_and_ethnicity_bucket(race_and_ethnicities)
          # Ignore the combinations we haven't setup (e.g. "RaceNone" with :unknown)
          next if buckets[bucket].nil?

          counted[bucket] ||= Set.new
          buckets[bucket] << id unless counted[bucket].include?(id)
          counted[bucket] << id
        end
      buckets
    end
  end

  private def race_and_ethnicity_columns
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

  def enrolled_by_race_and_ethnicity_data_for_chart
    @enrolled_by_race_and_ethnicity_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += enrolled_by_race_and_ethnicity.values.map(&:count)
      categories = enrolled_by_race_and_ethnicity.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |key| [[key[:race], key[:ethnicity]].join('-'), race_and_ethnicity_title(key)] }.to_h,
          chosen: @race_and_ethnicities,
          columns: columns,
          categories: categories.map { |key| [key[:race], key[:ethnicity]].join('-') },
        },
      )
    end
  end

  private def enrolled_by_race_and_ethnicity_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      race, ethnicity = sub_key.to_s.split('-')
      enrolled_by_race_and_ethnicity[{ race: race, ethnicity: ethnicity.to_sym }]
    else
      enrolled_by_race_and_ethnicity.values.flatten
    end
    details = enrolled.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
