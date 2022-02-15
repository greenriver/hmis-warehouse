###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting::Age
  extend ActiveSupport::Concern

  def exiting_by_age
    @exiting_by_age ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = age_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.order(first_date_in_program: :desc).
        pluck(:client_id, :age, :first_date_in_program).each do |id, age, _|
          counted[age_bucket(age)] ||= Set.new
          buckets[age_bucket(age)] << id unless counted[age_bucket(age)].include?(id)
          counted[age_bucket(age)] << id
        end
      buckets
    end
  end

  def exiting_by_age_data_for_chart
    @exiting_by_age_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_age.values.map(&:count)
      categories = entering_by_age.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, age_bucket_titles[s]] }.to_h,
          chosen: @age_ranges,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def exiting_by_age_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      exiting_by_age[sub_key]
    else
      exiting_by_age.values.flatten
    end
    details = exiting.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(age_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
