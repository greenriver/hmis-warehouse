###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Entering::Coc
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def entering_by_coc
    @entering_by_coc ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = coc_buckets.map { |b| [b, []] }.to_h
      counted = {}
      entering.joins(:enrollment_coc_at_entry).
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:household_id, ec_t[:CoCCode], :first_date_in_program).each do |id, coc, _|
          counted[coc_bucket(coc)] ||= Set.new
          buckets[coc_bucket(coc)] ||= []
          buckets[coc_bucket(coc)] << id unless counted[coc_bucket(coc)].include?(id)
          counted[coc_bucket(coc)] << id
        end
      buckets
    end
  end

  def entering_by_coc_data_for_chart
    @entering_by_coc_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += entering_by_coc.values.map(&:count)
      categories = entering_by_coc.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HUD.coc_name(s)] }.to_h,
          chosen: @coc_codes,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def entering_by_coc_details(options)
    sub_key = options[:sub_key]&.to_s
    ids = if sub_key
      entering_by_coc[sub_key]
    else
      entering_by_coc.values.flatten
    end
    details = entries_current_period.joins(:client, enrollment: :enrollment_coc_at_entry).
      where(household_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(coc_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      map do |row|
        row[-1] = "#{HUD.coc_name(row.last)} (#{row.last})"
        row
      end.
      index_by(&:first)
  end
end
