###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::LivingSituation
  extend ActiveSupport::Concern

  def enrolled
    open_enrollments.joins(:enrollment)
  end

  # Fetch first prior living situation for each client
  def prior_living_situations
    @prior_living_situations ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = HUD.living_situations.keys.map { |b| [b, []] }.to_h
      counted = Set.new
      enrolled.order(first_date_in_program: :desc).
        pluck(:client_id, she_t[:id], she_t[:housing_status_at_entry], :first_date_in_program).each do |c_id, en_id, situation, _|
        buckets[situation] ||= []
        # Store enrollment id so we can fetch details later, unique on client id
        buckets[situation] << en_id unless counted.include?(c_id)
        counted << c_id
      end

      # expose top 5 plus other, unless we've specified the situations, then use those.
      # Specifying the situations allows for comparison to the reporting period
      # FIXME: the problem is that the counts may differ between current and prior period
      # So the return order may not match
      all_situations = buckets.
        # Ignore blank, 8, 9, 99
        reject { |k, _| k.in?([nil, 8, 9, 99]) }.
        sort_by { |_, v| v.count }
      top_situations = all_situations.last(5).to_h
      summary = {}
      all_situations.each do |id, situation|
        type = ::HUD.situation_type(id, include_homeless_breakout: true)
        summary[type] ||= 0
        summary[type] += situation.count
      end
      top_situations[:other] = buckets.except(*top_situations.keys).
        map do |_, v|
          v
        end.flatten
      OpenStruct.new(
        {
          top: top_situations,
          summary: summary,
        },
      )
    end
  end

  def prior_living_situations_data_for_chart
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      columns = [@filter.date_range_words]
      columns += prior_living_situations.top.values.map(&:count).reverse
      categories = prior_living_situations.top.keys.reverse.map do |k|
        if k == :other
          'All others'
        else
          HUD.living_situation(k)
        end
      end
      {
        columns: columns,
        categories: categories,
        avg_columns: living_situation_avg_columns,
      }
    end
  end

  private def living_situation_avg_columns
    prior_living_situations.summary.map do |label, count|
      [
        "#{label} (#{number_with_delimiter(count)})",
        count,
      ]
    end.sort
  end

  def living_situation_bucket_titles
    HUD.living_situations
  end

  def enrolled_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      prior_living_situations.top.values.flatten.count
    end
  end

  private def living_situation_details(options)
    sub_key = if options[:sub_key].present?
      options[:sub_key]&.to_i
    else
      :other
    end

    ids = prior_living_situations.top[sub_key]
    details = enrolled.joins(:client, :enrollment).
      where(id: ids).
      order(first_date_in_program: :desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end

  private def living_situation_detail_headers(options)
    detail_columns(options).keys
  end
end
