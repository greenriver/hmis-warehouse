###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled::Veteran
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def enrolled_by_veteran
    buckets = veteran_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    enrolled.
      joins(:client).
      order(first_date_in_program: :desc).
      pluck(:client_id, c_t[:VeteranStatus], :first_date_in_program).each do |id, veteran_status, _|
        buckets[veteran_bucket(veteran_status)] << id unless counted.include?(id)
        counted << id
      end
    buckets
  end

  def enrolled_by_veteran_data_for_chart
    @enrolled_by_veteran_data_for_chart ||= begin
      columns = [date_range_words]
      columns += enrolled_by_veteran.values.map(&:count)
      categories = enrolled_by_veteran.keys.map do |type|
        HUD.veteran_status(type)
      end
      {
        columns: columns,
        categories: categories,
      }
    end
  end

  private def enrolled_by_veteran_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      enrolled_by_veteran[sub_key]
    else
      enrolled_by_veteran.values.flatten
    end
    details = enrolled.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(veteran_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
