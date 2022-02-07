###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Entering
  extend ActiveSupport::Concern
  include PerformanceDashboard::Household::Entering::Household
  include PerformanceDashboard::Household::Entering::ProjectType
  include PerformanceDashboard::Household::Entering::Coc

  def entering
    entries.distinct
  end

  def entering_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      entering.select(:household_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def entering_details(options)
    if options[:household]
      entering_by_household_details(options)
    elsif options[:project_type]
      entering_by_project_type_details(options)
    elsif options[:coc]
      entering_by_coc_details(options)
    end
  end

  private def entering_detail_headers(options)
    detail_columns(options).keys
  end
end
