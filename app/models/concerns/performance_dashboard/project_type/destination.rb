###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::Destination
  extend ActiveSupport::Concern

  # Fetch last destination for each client
  def destinations
    @destinations ||= begin
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
      top_destinations = buckets.
        # Ignore blank, 8, 9, 99
        reject { |k, _| k.in?([nil, 8, 9, 99]) }.
        sort_by { |_, v| v.count }.
        last(10).to_h
      top_destinations[:other] = buckets.except(*top_destinations.keys).
        map do |_, v|
          v
        end.flatten
      top_destinations
    end
  end

  def destinations_data_for_chart
    @destinations_data_for_chart ||= begin
      columns = [date_range_words]
      columns += destinations.values.map(&:count).reverse
      categories = destinations.keys.reverse.map do |k|
        if k == :other
          'All others'
        else
          HUD.destination(k)
        end
      end
      {
        columns: columns,
        categories: categories,
      }
    end
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
