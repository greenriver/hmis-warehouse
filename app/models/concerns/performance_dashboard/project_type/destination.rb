###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::Destination
  extend ActiveSupport::Concern

  # Fetch last destination for each client
  def destinations
    @destinations ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = HUD.valid_destinations.keys.map { |b| [b, []] }.to_h
      counted = Set.new
      exits_current_period.
        order(last_date_in_program: :desc).
        pluck(:client_id, she_t[:id], she_t[:destination], :first_date_in_program).each do |c_id, en_id, destination, _|
        buckets[destination] ||= []
        # Store enrollment id so we can fetch details later, unique on client id
        buckets[destination] << en_id unless counted.include?(c_id)
        counted << c_id
      end

      # expose top 10 plus other
      all_destinations = buckets.
        # Ignore blank, 8, 9, 99
        reject { |k, _| k.in?([nil, 8, 9, 99]) }.
        sort_by { |_, v| v.count }
      top_destinations = all_destinations.last(5).to_h
      summary = {}
      all_destinations.each do |id, dests|
        type = ::HUD.destination_type(id)
        summary[type] ||= 0
        summary[type] += dests.count
      end
      top_destinations[:other] = buckets.except(*top_destinations.keys).
        map do |_, v|
          v
        end.flatten
      OpenStruct.new(
        {
          top: top_destinations,
          summary: summary,
        },
      )
    end
  end

  def exiting_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      exits.distinct.select(:client_id).count
    end
  end

  def destinations_data_for_chart
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      columns = [@filter.date_range_words]
      columns += destinations.top.values.map(&:count).reverse
      categories = destinations.top.keys.reverse.map do |k|
        if k == :other
          'All others'
        else
          HUD.destination(k)
        end
      end
      {
        columns: columns,
        categories: categories,
        avg_columns: destination_avg_columns,
      }
    end
  end

  private def destination_avg_columns
    destinations.summary.map do |label, count|
      [
        "#{label} (#{number_with_delimiter(count)})",
        count,
      ]
    end.sort
  end

  def destination_bucket_titles
    HUD.valid_destinations
  end

  private def destination_details(options)
    sub_key = if options[:sub_key].present?
      options[:sub_key]&.to_i
    else
      :other
    end

    ids = destinations[sub_key]
    details = exits_current_period.joins(:client, :enrollment).
      where(id: ids).
      order(last_date_in_program: :desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end

  private def destination_detail_headers(options)
    detail_columns(options).keys
  end
end
