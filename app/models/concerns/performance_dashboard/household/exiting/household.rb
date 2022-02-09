###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Exiting::Household
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_household
    @exiting_by_household ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = household_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.
        joins(:client).
        order(first_date_in_program: :desc).
        select(:household_id, :age, :other_clients_under_18, :other_clients_between_18_and_25, :other_clients_over_25, :first_date_in_program).
        each do |row|
          counted[household_bucket(row)] ||= Set.new
          buckets[household_bucket(row)] << row.household_id unless counted[household_bucket(row)].include?(row.household_id)
          counted[household_bucket(row)] << row.household_id
        end
      buckets
    end
  end

  def exiting_by_household_data_for_chart
    @exiting_by_household_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_household.values.map(&:count).drop(1) # ignore :all
      categories = exiting_by_household.keys.drop(1) # ignore :all
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, household_type(s)] }.to_h,
          chosen: [@household_type].compact,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def exiting_by_household_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      exiting_by_household[sub_key]
    else
      exiting_by_household.values.flatten
    end
    details = exiting.joins(:client).
      where(household_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(household_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
