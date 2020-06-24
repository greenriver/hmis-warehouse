###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled::Ethnicity
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def enrolled_by_ethnicity
    buckets = ethnicity_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    enrolled.
      joins(:client).
      order(first_date_in_program: :desc).
      pluck(:client_id, :Ethnicity, :first_date_in_program).each do |id, ethnicity, _|
        buckets[ethnicity_bucket(ethnicity)] << id unless counted.include?(id)
        counted << id
      end
    buckets
  end

  def enrolled_by_ethnicity_data_for_chart
    @enrolled_by_ethnicity_data_for_chart ||= begin
      columns = [date_range_words]
      columns += enrolled_by_ethnicity.values.map(&:count)
      categories = enrolled_by_ethnicity.keys.map do |type|
        HUD.ethnicity(type)
      end
      {
        columns: columns, # ignore :all
        categories: categories, # ignore :all
      }
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
