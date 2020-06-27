###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::Detail
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
    when 'Gender'
      HUD.gender(column)
    when 'Ethnicity'
      HUD.ethnicity(column)
    when HUD.race('AmIndAKNative'), HUD.race('Asian'), HUD.race('BlackAfAmerican'), HUD.race('NativeHIOtherPacific'), HUD.race('White'), HUD.race('RaceNone')
      HUD.no_yes_reasons_for_missing_data(column)
    when 'Veteran Status'
      HUD.veteran_status(column)
    when 'Individual Adult', 'Child Only'
      yn(column)
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
      if options[:age].present?
        title += " #{age_bucket_titles[sub_key.to_sym]}"
      elsif options[:gender].present?
        title += " #{gender_bucket_titles[sub_key.to_i]}"
      elsif options[:household].present?
        title += " #{household_bucket_titles[sub_key.to_i]}"
      elsif options[:veteran].present?
        title += " #{veteran_bucket_titles[sub_key.to_i]}"
      elsif options[:race].present?
        title += " #{race_bucket_titles[sub_key.to_s]}"
      elsif options[:ethnicity].present?
        title += " #{ethnicity_bucket_titles[sub_key.to_i]}"
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
    columns['Veteran Status'] = c_t[:VeteranStatus] if options[:veteran]
    if options[:race]
      HUD.races.each do |k, title|
        columns[title] = c_t[k.to_sym]
      end
    end
    columns['Ethnicity'] = c_t[:Ethnicity] if options[:ethnicity]
    columns
  end
end
