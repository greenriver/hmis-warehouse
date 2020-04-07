###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboardOverviewDetail
  extend ActiveSupport::Concern

  def detail_for(options)
    return unless options[:key]

    case options[:key]
    when :entering
      entering_details
    end
  end

  def header_for(options)
    return unless options[:key]

    case options[:key]
    when :entering
      entering_detail_headers
    end
  end

  private def entering_details
    entering.joins(:client).pluck(*entering_detail_columns.values)
  end

  private def entering_detail_columns
    {
      'Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
    }
  end

  private def entering_detail_headers
    entering_detail_columns.keys
  end
end
