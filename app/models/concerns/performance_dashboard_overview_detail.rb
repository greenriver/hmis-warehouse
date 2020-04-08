###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboardOverviewDetail
  extend ActiveSupport::Concern

  def detail_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_details(options)
    end
  end

  def header_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_detail_headers(options)
    end
  end

  def support_title(key:, sub_key: nil, breakdown:)
    title = case key.to_sym
    when :entering
      'Clients Entering'
    when :exiting
      'Clients Exiting'
    end
    title += " #{sub_key.to_s.humanize}" if sub_key
    title += " #{breakdown}"
    title
  end

  private def entering_details(options)
    entering.
      joins(:client).
      order(c_t[:LastName].asc, c_t[:FirstName].asc).
      pluck(*entering_detail_columns(options).values).
      group_by(&:first)
  end

  private def entering_detail_columns(options)
    columns = {
      'Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
      'Exit Date' => she_t[:last_date_in_program],
    }
    # Add any additional columns
    columns['Age'] = she_t[:age] if options[:age]
    columns
  end

  private def entering_detail_headers(options)
    entering_detail_columns(options).keys
  end
end
