###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled::Ethnicity
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def enrolled_by_ethnicity
    @enrolled_by_ethnicity ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = ethnicity_buckets.map { |b| [b, []] }.to_h
      counted = {}
      enrolled.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, :Ethnicity, :first_date_in_program).each do |id, ethnicity, _|
          counted[ethnicity_bucket(ethnicity)] ||= Set.new
          buckets[ethnicity_bucket(ethnicity)] << id unless counted[ethnicity_bucket(ethnicity)].include?(id)
          counted[ethnicity_bucket(ethnicity)] << id
        end
      buckets
    end
  end

  def enrolled_by_ethnicity_data_for_chart
    @enrolled_by_ethnicity_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += enrolled_by_ethnicity.values.map(&:count)
      categories = enrolled_by_ethnicity.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HUD.ethnicity(s)] }.to_h,
          chosen: @ethnicities,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def enrolled_by_ethnicity_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      enrolled_by_ethnicity[sub_key]
    else
      enrolled_by_ethnicity.values.flatten
    end
    details = enrolled.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(ethnicity_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
