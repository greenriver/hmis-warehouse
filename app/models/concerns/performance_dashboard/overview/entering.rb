###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Entering
  extend ActiveSupport::Concern
  include PerformanceDashboard::Overview::Entering::Age
  include PerformanceDashboard::Overview::Entering::Gender
  include PerformanceDashboard::Overview::Entering::Household
  include PerformanceDashboard::Overview::Entering::Veteran
  include PerformanceDashboard::Overview::Entering::Race
  include PerformanceDashboard::Overview::Entering::Ethnicity
  include PerformanceDashboard::Overview::Entering::ProjectType
  include PerformanceDashboard::Overview::Entering::Coc
  include PerformanceDashboard::Overview::Entering::LotHomeless

  def entering
    entries.distinct
  end

  def entering_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      entering.select(:client_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def entering_details(options)
    if options[:age]
      entering_by_age_details(options)
    elsif options[:gender]
      entering_by_gender_details(options)
    elsif options[:household]
      entering_by_household_details(options)
    elsif options[:veteran]
      entering_by_veteran_details(options)
    elsif options[:race]
      entering_by_race_details(options)
    elsif options[:ethnicity]
      entering_by_ethnicity_details(options)
    elsif options[:project_type]
      entering_by_project_type_details(options)
    elsif options[:coc]
      entering_by_coc_details(options)
    elsif options[:lot_homeless]
      entering_by_lot_homeless_details(options)
    end
  end

  private def entering_detail_headers(options)
    detail_columns(options).keys
  end
end
