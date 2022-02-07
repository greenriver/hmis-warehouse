###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::ProjectType::Detail
  extend ActiveSupport::Concern

  def detail_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :living_situation
      living_situation_details(options)
    when :destination
      destination_details(options)
    when :length_of_time
      length_of_time_details(options)
    when :returns
      returns_details(options)
    end
  end

  def header_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :living_situation
      living_situation_detail_headers(options)
    when :destination
      destination_detail_headers(options)
    when :length_of_time
      length_of_time_detail_headers(options)
    when :returns
      returns_detail_headers(options)
    end
  end

  def detail_column_display(header:, column:)
    case header
    when 'Living Situation'
      HUD.living_situation(column)
    when 'Destination'
      HUD.destination(column)
    when 'Individual Adult', 'Child Only'
      yn(column)
    else
      column
    end
  end

  def support_title(options)
    key = options[:key].to_s
    sub_key = options[:sub_key]
    title = 'Clients: '
    if sub_key
      if options[:living_situation].present?
        title += " #{living_situation_bucket_titles[sub_key.to_i]}"
      elsif options[:destination].present?
        title += " #{destination_bucket_titles[sub_key.to_i]}"
      elsif options[:length_of_time].present?
        title += " #{time_bucket_titles[sub_key.to_sym]}"
      elsif options[:returns].present?
        title += " #{returns_bucket_titles[sub_key.to_sym]}"
      end
    end
    title += " #{key.titleize}"
    title
  end

  private def detail_columns(options)
    columns = {
      'Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
      'Exit Date' => she_t[:last_date_in_program],
    }
    # Add any additional columns
    columns['Living Situation'] = e_t[:LivingSituation] if options[:living_situation]
    columns['Destination'] = she_t[:destination] if options[:destination]
    columns
  end
end
