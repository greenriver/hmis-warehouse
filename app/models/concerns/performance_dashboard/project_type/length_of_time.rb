###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::LengthOfTime
  extend ActiveSupport::Concern

  def services
    open_enrollments.joins(:service_history_services).
      merge(GrdaWarehouse::ServiceHistoryService.service_between(
              start_date: @end_date - 3.years,
              end_date: @end_date,
            ))
  end

  # Note Handle PH differently
  # return false if GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(project.computed_project_type) &&
  #       (self.MoveInDate.present? && date > self.MoveInDate)
  #     return nil

  # Fetch service during range, sum unique days within 3 years of end date
  def lengths_of_time
    @lengths_of_time ||= begin
      buckets = time_buckets.map { |b| [b, []] }.to_h
      counted = Set.new
      services.
        distinct.
        select(shs_t[:date]).
        group(:client_id).
        count.
        each do |c_id, date_count|
        buckets[time_bucket(date_count)] << c_id unless counted.include?(c_id)
        counted << c_id
      end
      buckets
    end
  end

  private def time_buckets
    [
      :less_than_thirty,
      :thirty_to_sixty,
      :sixty_to_ninety,
      :ninety_to_one_twenty,
      :one_twenty_to_one_eighty,
      :one_eighty_to_one_year,
      :more_than_a_year,
    ].freeze
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
    @lengths_of_time_data_for_chart ||= begin
      columns = [date_range_words]
      columns += lengths_of_time.values.map(&:count)
      categories = lengths_of_time.keys.map do |k|
        time_bucket_titles[k]
      end
      {
        columns: columns,
        categories: categories,
      }
    end
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
