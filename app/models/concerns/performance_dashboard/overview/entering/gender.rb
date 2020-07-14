###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Entering::Gender
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_gender
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = gender_buckets.map { |b| [b, []] }.to_h
      counted = Set.new
      entering.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, c_t[:Gender], :first_date_in_program).each do |id, gender, _|
        buckets[gender_bucket(gender)] << id unless counted.include?(id)
        counted << id
      end
      buckets
    end
  end

  def entering_by_gender_data_for_chart
    @entering_by_gender_data_for_chart ||= begin
      columns = [date_range_words]
      columns += entering_by_gender.values.map(&:count)
      categories = entering_by_gender.keys.map { |g| HUD.gender(g) }
      filter_selected_data_for_chart({
        chosen: chosen_genders,
        columns: columns,
        categories: categories,
      })
    end
  end

  private def entering_by_gender_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      entering_by_gender[sub_key]
    else
      entering_by_gender.values.flatten
    end
    details = entries_current_period.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(gender_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      map do |row|
        row[-1] = "#{HUD.gender(row.last)} (#{row.last})"
        row
      end.
      index_by(&:first)
  end
end
