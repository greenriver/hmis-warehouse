###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Household::Detail
  extend ActiveSupport::Concern

  def detail_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_details(options)
    when :exiting
      exiting_details(options)
    when :enrolled
      enrolled_details(options)
    end
  end

  def header_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_detail_headers(options)
    when :exiting
      exiting_detail_headers(options)
    when :enrolled
      enrolled_detail_headers(options)
    end
  end

  def detail_column_display(header:, column:)
    case header
    when 'Individual Adult', 'Child Only'
      yn(column)
    when 'Project Type'
      HUD.project_type(column)
    when 'CoC'
      HUD.coc_name(column)
    else
      column
    end
  end

  def support_title(options)
    key = options[:key].to_s
    sub_key = options[:sub_key]
    breakdown = options[:breakdown]
    title = 'Clients: '
    if sub_key
      if options[:household].present?
        title += " #{household_bucket_titles[sub_key.to_i]}"
      elsif options[:project_type].present?
        title += " #{project_type_bucket_titles[sub_key.to_i]}"
      elsif options[:coc].present?
        title += " #{coc_bucket_titles[sub_key.to_s]}"
      end
    end
    title += " #{key.titleize} #{breakdown}"
    title
  end

  private def detail_columns(options)
    columns = {
      'Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Household ID' => she_t[:household_id],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
      'Exit Date' => she_t[:last_date_in_program],
    }
    # Add any additional columns
    if options[:household]
      columns['Age'] = she_t[:age]
      columns['Other Clients Under 18'] = she_t[:other_clients_under_18]
      columns['Other Clients 18 to 25'] = she_t[:other_clients_between_18_and_25]
      columns['Other Clients over 25'] = she_t[:other_clients_over_25]
    end
    columns['Project Type'] = she_t[project_type_col] if options[:project_type]
    columns['CoC'] = ec_t[:CoCCode] if options[:coc]
    columns
  end
end
