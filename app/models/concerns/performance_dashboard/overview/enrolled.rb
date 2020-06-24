###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled
  extend ActiveSupport::Concern
  include PerformanceDashboard::Overview::Enrolled::Age
  include PerformanceDashboard::Overview::Enrolled::Gender
  include PerformanceDashboard::Overview::Enrolled::Household
  include PerformanceDashboard::Overview::Enrolled::Veteran
  include PerformanceDashboard::Overview::Enrolled::Race
  include PerformanceDashboard::Overview::Enrolled::Ethnicity

  def enrolled
    open_enrollments.distinct
  end

  def enrolled_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      enrolled.select(:client_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def enrolled_details(options)
    if options[:age]
      enrolled_by_age_details(options)
    elsif options[:gender]
      enrolled_by_gender_details(options)
    elsif options[:household]
      enrolled_by_household_details(options)
    elsif options[:veteran]
      enrolled_by_veteran_details(options)
    elsif options[:race]
      enrolled_by_race_details(options)
    elsif options[:ethnicity]
      enrolled_by_ethnicity_details(options)
    end
  end

  private def enrolled_detail_headers(options)
    detail_columns(options).keys
  end
end
