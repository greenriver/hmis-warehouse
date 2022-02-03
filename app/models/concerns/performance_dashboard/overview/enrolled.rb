###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Enrolled
  extend ActiveSupport::Concern
  include PerformanceDashboard::Overview::Enrolled::Age
  include PerformanceDashboard::Overview::Enrolled::Gender
  include PerformanceDashboard::Overview::Enrolled::Household
  include PerformanceDashboard::Overview::Enrolled::Veteran
  include PerformanceDashboard::Overview::Enrolled::Race
  include PerformanceDashboard::Overview::Enrolled::Ethnicity
  include PerformanceDashboard::Overview::Enrolled::ProjectType
  include PerformanceDashboard::Overview::Enrolled::Coc
  include PerformanceDashboard::Overview::Enrolled::LotHomeless

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
    elsif options[:project_type]
      enrolled_by_project_type_details(options)
    elsif options[:coc]
      enrolled_by_coc_details(options)
    elsif options[:lot_homeless]
      enrolled_by_lot_homeless_details(options)
    end
  end

  private def enrolled_detail_headers(options)
    detail_columns(options).keys
  end
end
