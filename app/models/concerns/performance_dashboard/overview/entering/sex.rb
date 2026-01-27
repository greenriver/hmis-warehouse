###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceDashboard::Overview::Entering::Sex
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_sex
    @entering_by_sex ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: PerformanceDashboards::Overview::EXPIRATION_LENGTH) do
      buckets = sex_buckets.map { |b| [b, []] }.to_h
      counted = {}
      entering.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, c_t[:Sex], :first_date_in_program).each do |row|
          id = row.first
          _entry_date = row.last
          sex_value = row[1]
          sex = sex_value.presence || 99
          next unless sex_buckets.include?(sex)

          counted[sex_bucket(sex)] ||= Set.new
          buckets[sex_bucket(sex)] << id unless counted[sex_bucket(sex)].include?(id)
          counted[sex_bucket(sex)] << id
        end
      buckets
    end
  end

  def entering_by_sex_data_for_chart
    @entering_by_sex_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += entering_by_sex.values.map(&:count)
      categories = entering_by_sex.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HudHelper.util.sex(s)] }.to_h,
          chosen: @sexes,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def entering_by_sex_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      entering_by_sex[sub_key]
    else
      entering_by_sex.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(sex_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
