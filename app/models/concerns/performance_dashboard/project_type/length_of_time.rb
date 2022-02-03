###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::LengthOfTime
  extend ActiveSupport::Concern

  def services
    open_enrollments.service_within_date_range(
      start_date: @end_date - 3.years,
      end_date: @end_date,
    )
  end

  # Note Handle PH differently
  # return false if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(project.computed_project_type) &&
  #       (self.MoveInDate.present? && date > self.MoveInDate)
  #     return nil

  # Fetch service during range, sum unique days within 3 years of end date
  def lengths_of_time
    @lengths_of_time ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      buckets = time_buckets.map { |b| [b, []] }.to_h
      counted = Set.new
      time_counts.each do |c_id, date_count|
        buckets[time_bucket(date_count)] << c_id unless counted.include?(c_id)
        counted << c_id
      end
      buckets
    end
  end

  private def time_counts
    @time_counts ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      services.
        distinct.
        select(shs_t[:date]).
        group(:client_id).
        count
    end
  end

  def enrolled_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      open_enrollments.with_service_between(
        start_date: @end_date - 3.years,
        end_date: @end_date,
        service_scope: GrdaWarehouse::ServiceHistoryService.where(service_history_enrollment_id: open_enrollments.select(:id)),
      ).select(:client_id).distinct.count
    end
  end

  def time_bucket_titles
    {
      less_than_thirty: '< 30 days',
      thirty_to_sixty: '30 to 60 days',
      sixty_to_ninety: '61 to 90 days',
      ninety_to_one_twenty: '91 to 120 days',
      one_twenty_to_one_eighty: '121 to 180 days',
      one_eighty_to_one_year: '181 to 365 days',
      more_than_a_year: '> 1 year',
    }.freeze
  end

  private def time_buckets
    time_bucket_titles.keys
  end

  def time_bucket(time)
    if time < 30
      :less_than_thirty
    elsif time >= 30 && time <= 60
      :thirty_to_sixty
    elsif time >= 61 && time <= 90
      :sixty_to_ninety
    elsif time >= 91 && time <= 120
      :ninety_to_one_twenty
    elsif time >= 121 && time <= 180
      :one_twenty_to_one_eighty
    elsif time >= 181 && time <= 365
      :one_eighty_to_one_year
    elsif time >= 366
      :more_than_a_year
    end
  end

  def lengths_of_time_data_for_chart
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      columns = [@filter.date_range_words]
      counts = lengths_of_time.values.map(&:count)
      columns += counts
      categories = lengths_of_time.keys.map do |k|
        time_bucket_titles[k]
      end
      {
        columns: columns,
        categories: categories,
        summary_datum: [
          { name: 'Max', value: "#{time_counts.values.max} days" },
          { name: 'Average', value: "#{number_with_delimiter(mean(time_counts.values))} days" },
          { name: 'Median', value: "#{number_with_delimiter(median(time_counts.values))} days" },
        ],
      }
    end
  end

  def mean(values)
    return 0 unless values.any?

    values = values.map(&:to_f)
    (values.sum.to_f / values.length).round
  end

  def median(values)
    return 0 unless values.any?

    values = values.map(&:to_f)
    mid = values.size / 2
    sorted = values.sort
    values.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2
  end

  private def length_of_time_details(options)
    sub_key = options[:sub_key]&.to_sym

    ids = lengths_of_time[sub_key]
    details = enrolled.joins(:client, :enrollment).
      where(client_id: ids).
      order(last_date_in_program: :desc)
    details.pluck(*detail_columns(options).values).
      index_by(&:first)
  end

  private def length_of_time_detail_headers(options)
    detail_columns(options).keys
  end
end
