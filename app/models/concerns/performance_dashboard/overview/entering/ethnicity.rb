###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Entering::Ethnicity
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_ethnicity
    @entering_by_ethnicity ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: PerformanceDashboards::Overview::EXPIRATION_LENGTH) do
      buckets = ethnicity_buckets.map { |b| [b, []] }.to_h
      counted = {}
      entering.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, :first_date_in_program, *ethnicity_columns).
        each do |id, _, *cols|
          ethnicities = ethnicity_columns.zip(cols).to_h
          bucket = ethnicity_bucket(ethnicities)
          counted[bucket] ||= Set.new
          buckets[bucket] << id unless counted[bucket].include?(id)
          counted[bucket] << id
        end
      buckets
    end
  end

  # NOTE: we need all the race categories to correctly identify RaceNone
  private def ethnicity_columns
    [
      :HispanicLatinaeo,
      :RaceNone,
    ].freeze
  end

  def entering_by_ethnicity_data_for_chart
    @entering_by_ethnicity_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += entering_by_ethnicity.values.map(&:count)
      categories = entering_by_ethnicity.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HudUtility2024.ethnicity(s.to_sym)] }.to_h,
          chosen: @ethnicities,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def entering_by_ethnicity_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      entering_by_ethnicity[sub_key]
    else
      entering_by_ethnicity.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
