###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Exiting
  extend ActiveSupport::Concern
  include PerformanceDashboard::Household::Exiting::Household
  include PerformanceDashboard::Household::Exiting::ProjectType
  include PerformanceDashboard::Household::Exiting::Coc

  def exiting
    exits.distinct
  end

  def exiting_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      exiting.select(:household_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def exiting_details(options)
    if options[:household]
      exiting_by_household_details(options)
    elsif options[:project_type]
      exiting_by_project_type_details(options)
    elsif options[:coc]
      exiting_by_coc_details(options)
    end
  end

  private def exiting_detail_headers(options)
    detail_columns(options).keys
  end
end
