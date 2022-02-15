###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Exiting
  extend ActiveSupport::Concern
  include PerformanceDashboard::Overview::Exiting::Age
  include PerformanceDashboard::Overview::Exiting::Gender
  include PerformanceDashboard::Overview::Exiting::Household
  include PerformanceDashboard::Overview::Exiting::Veteran
  include PerformanceDashboard::Overview::Exiting::Race
  include PerformanceDashboard::Overview::Exiting::Ethnicity
  include PerformanceDashboard::Overview::Exiting::ProjectType
  include PerformanceDashboard::Overview::Exiting::Coc
  include PerformanceDashboard::Overview::Exiting::LotHomeless

  def exiting
    exits.distinct
  end

  def exiting_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      exiting.select(:client_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def exiting_details(options)
    if options[:age]
      exiting_by_age_details(options)
    elsif options[:gender]
      exiting_by_gender_details(options)
    elsif options[:household]
      exiting_by_household_details(options)
    elsif options[:veteran]
      exiting_by_veteran_details(options)
    elsif options[:race]
      exiting_by_race_details(options)
    elsif options[:ethnicity]
      exiting_by_ethnicity_details(options)
    elsif options[:project_type]
      exiting_by_project_type_details(options)
    elsif options[:coc]
      exiting_by_coc_details(options)
    elsif options[:lot_homeless]
      exiting_by_lot_homeless_details(options)
    end
  end

  private def exiting_detail_headers(options)
    detail_columns(options).keys
  end
end
