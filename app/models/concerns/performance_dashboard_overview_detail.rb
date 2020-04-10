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
    title = 'Clients'
    title += " #{sub_key.to_s.humanize.titleize}" if sub_key
    title += " #{key.to_s.titleize} #{breakdown}"
    title
  end

  # Only return the most-recent matching enrollment for each client
  private def entering_details(options)
    details = entering.
      joins(:client).
      order(she_t[:first_date_in_program].desc)
    details = details.where(age_query(options[:sub_key])) if options[:sub_key]&.to_sym
    details.pluck(*entering_detail_columns(options).values).
      index_by(&:first)
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
