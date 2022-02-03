###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Enrolled
  extend ActiveSupport::Concern
  include PerformanceDashboard::Household::Enrolled::Household
  include PerformanceDashboard::Household::Enrolled::ProjectType
  include PerformanceDashboard::Household::Enrolled::Coc

  def enrolled
    open_enrollments.distinct
  end

  def enrolled_total_count
    Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: 5.minutes) do
      enrolled.select(:household_id).count
    end
  end

  # Only return the most-recent matching enrollment for each client
  private def enrolled_details(options)
    if options[:household]
      enrolled_by_household_details(options)
    elsif options[:project_type]
      enrolled_by_project_type_details(options)
    elsif options[:coc]
      enrolled_by_coc_details(options)
    end
  end

  private def enrolled_detail_headers(options)
    detail_columns(options).keys
  end
end
