###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting::LotHomeless
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_lot_homeless
    @exiting_by_lot_homeless ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = lot_homeless_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.preload(:processed_client).order(first_date_in_program: :desc).each do |client|
        next unless client.processed_client
        lot = client.processed_client.days_homeless_last_three_years
          counted[lot_homeless_bucket(lot)] ||= Set.new
          buckets[lot_homeless_bucket(lot)] << client.client_id unless counted[lot_homeless_bucket(lot)].include?(client.client_id)
          counted[lot_homeless_bucket(lot)] << client.client_id
      end
      buckets
    end
  end

  def exiting_by_lot_homeless_data_for_chart
    @exiting_by_lot_homeless_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_lot_homeless.values.map(&:count)
      categories = exiting_by_lot_homeless.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, lot_homeless_bucket_titles[s]] }.to_h,
          chosen: @lot_homeless_ranges,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def exiting_by_lot_homeless_details(options)
    sub_key = options[:sub_key]&.to_sym
    ids = if sub_key
      exiting_by_lot_homeless[sub_key]
    else
      exiting_by_lot_homeless.values.flatten
    end
    details = exiting.joins(:client, :processed_client).
      where(client_id: ids).
      order(first_date_in_program: :desc)
    details = details.where(lot_homeless_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
