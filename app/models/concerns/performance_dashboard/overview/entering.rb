###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Entering # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern
  include PerformanceDashboard::Overview::Entering::Age
  include PerformanceDashboard::Overview::Entering::Gender
  include PerformanceDashboard::Overview::Entering::Household

  def entering
    entries.distinct
  end

  def entering_total_count
    entering.select(:client_id).count
  end

  # Only return the most-recent matching enrollment for each client
  private def entering_details(options)
    if options[:age]
      entering_by_age_details(options)
    elsif options[:gender]
      entering_by_gender_details(options)
    elsif options[:household]
      entering_by_household_details(options)
    end
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
    columns['Gender'] = c_t[:Gender] if options[:gender]
    if options[:household]
      columns['Age'] = she_t[:age]
      columns['Other Clients Under 18'] = she_t[:other_clients_under_18]
      columns['Individual Adult'] = she_t[:individual_adult]
      columns['Child Only'] = she_t[:children_only]
    end
    columns
  end

  private def entering_detail_headers(options)
    entering_detail_columns(options).keys
  end
end
