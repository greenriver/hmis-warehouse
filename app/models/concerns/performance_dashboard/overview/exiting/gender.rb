###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting::Gender
  extend ActiveSupport::Concern

  # NOTE: always count the most-recently started enrollment within the range
  def exiting_by_gender
    @exiting_by_gender ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = gender_buckets.map { |b| [b, []] }.to_h
      counted = {}
      exiting.
        joins(:client).
        order(first_date_in_program: :desc).
        pluck(:client_id, *HUD.gender_fields.map { |g| c_t[g] }, :first_date_in_program).each do |row|
          id = row.first
          _entry_date = row.last
          row = row.slice(1..-1) # remove first and last elements from the row
          genders = HUD.gender_fields.map.with_index do |k, i|
            if k == :GenderNone
              row[i]
            elsif row[i] == 1
              HUD.gender_id_to_field_name.invert[k]
            end
          end.compact
          next unless genders.present?

          genders.each do |gender|
            counted[gender_bucket(gender)] ||= Set.new
            buckets[gender_bucket(gender)] << id unless counted[gender_bucket(gender)].include?(id)
            counted[gender_bucket(gender)] << id
          end
        end
      buckets
    end
  end

  def exiting_by_gender_data_for_chart
    @exiting_by_gender_data_for_chart ||= begin
      columns = [@filter.date_range_words]
      columns += exiting_by_gender.values.map(&:count)
      categories = exiting_by_gender.keys
      filter_selected_data_for_chart(
        {
          labels: categories.map { |s| [s, HUD.gender(s)] }.to_h,
          chosen: @genders,
          columns: columns,
          categories: categories,
        },
      )
    end
  end

  private def exiting_by_gender_details(options)
    sub_key = options[:sub_key]&.to_i
    ids = if sub_key
      exiting_by_gender[sub_key]
    else
      exiting_by_gender.values.flatten
    end
    details = exiting.joins(:client).
      where(client_id: ids).
      order(she_t[:first_date_in_program].desc)
    details = details.where(gender_query(sub_key)) if sub_key
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end
end
