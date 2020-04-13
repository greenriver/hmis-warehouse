###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting::Gender # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_gender
    buckets = gender_buckets.map { |b| [b, []] }.to_h
    counted = Set.new
    exiting.
      joins(:client).
      order(first_date_in_program: :desc).
      pluck(:client_id, c_t[:Gender], :first_date_in_program).each do |id, gender, _|
      buckets[gender_bucket(gender)] << id unless counted.include?(id)
      counted << id
    end
    buckets
  end

  def exiting_by_gender_data_for_chart
    @exiting_by_gender_data_for_chart ||= begin
      columns = [(@start_date..@end_date).to_s]
      columns += exiting_by_gender.values.map(&:count)
      {
        columns: columns,
        categories: exiting_by_gender.keys.map { |g| HUD.gender(g) },
      }
    end
  end

  private def exiting_by_gender_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      exiting_by_gender[sub_key]
    else
      exiting_by_gender.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(gender_query(sub_key)) if sub_key
    details.pluck(*exiting_detail_columns(options).values).
      map do |row|
        row[-1] = "#{HUD.gender(row.last)} (#{row.last})"
        row
      end.
      index_by(&:first)
  end
end
