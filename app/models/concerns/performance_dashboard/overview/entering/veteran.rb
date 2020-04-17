###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Entering::Veteran # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_veteran
    buckets = veteran_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    entering.
      joins(:client).
      order(first_date_in_program: :desc).
      pluck(:client_id, c_t[:VeteranStatus], :first_date_in_program).each do |id, veteran_status, _|
        buckets[veteran_bucket(veteran_status)] << id unless counted.include?(id)
        counted << id
      end
    buckets
  end

  def entering_by_veteran_data_for_chart
    @entering_by_veteran_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += entering_by_veteran.values.map(&:count)
      categories = entering_by_veteran.keys.map do |type|
        HUD.veteran_status(type)
      end
      {
        columns: columns,
        categories: categories,
      }
    end
  end

  private def entering_by_veteran_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      entering_by_veteran[sub_key]
    else
      entering_by_veteran.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(veteran_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
