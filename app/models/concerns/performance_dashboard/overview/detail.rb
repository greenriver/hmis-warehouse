###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
    when 'Female', 'Male', 'No Single Gender', 'Transgender', 'Questioning', 'Unknown Gender'
      HudUtility.no_yes_reasons_for_missing_data(column)
    when 'Ethnicity'
      HudUtility.ethnicity(column)
    when HudUtility.race('AmIndAKNative'), HudUtility.race('Asian'), HudUtility.race('BlackAfAmerican'), HudUtility.race('NativeHIPacific'), HudUtility.race('White'), HudUtility.race('RaceNone')
      HudUtility.no_yes_reasons_for_missing_data(column)
    when 'Veteran Status'
      HudUtility.veteran_status(column)
    when 'Individual Adult', 'Child Only'
      yn(column)
    when 'Project Type'
      HudUtility.project_type(column)
    when 'CoC'
      HudUtility.coc_name(column)
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
      elsif options[:project_type].present?
        title += " #{project_type_bucket_titles[sub_key.to_i]}"
      elsif options[:coc].present?
        title += " #{coc_bucket_titles[sub_key.to_s]}"
      elsif options[:lot_homeless].present?
        title += " #{lot_homeless_bucket_titles[sub_key.to_sym]}"
      end
    end
    title += " #{key.titleize} #{breakdown}"
    title
  end

  private def detail_columns(options)
    columns = {
      'Warehouse Client ID' => she_t[:client_id],
      'First Name' => c_t[:FirstName],
      'Last Name' => c_t[:LastName],
      'Project' => she_t[:project_name],
      'Entry Date' => she_t[:first_date_in_program],
      'Exit Date' => she_t[:last_date_in_program],
    }

    exclude_pii = options[:export] && !::GrdaWarehouse::Config.get(:include_pii_in_detail_downloads)
    columns = columns.except('First Name', 'Last Name') if exclude_pii

    # Add any additional columns
    columns['Reporting Age'] = age_calculation if options[:age]
    columns['DOB'] = c_t[:DOB] if options[:age] && !exclude_pii
    if options[:gender]
      columns['Female'] = c_t[:Female]
      columns['Male'] = c_t[:Male]
      columns['No Single Gender'] = c_t[:NoSingleGender]
      columns['Transgender'] = c_t[:Transgender]
      columns['Questioning'] = c_t[:Questioning]
      columns['Unknown Gender'] = c_t[:GenderNone]
    end
    if options[:household]
      columns['Reporting Age'] = age_calculation
      columns['DOB'] = c_t[:DOB] unless exclude_pii
      columns['Other Clients Under 18'] = she_t[:other_clients_under_18]
      columns['Other Clients 18 to 25'] = she_t[:other_clients_between_18_and_25]
      columns['Other Clients over 25'] = she_t[:other_clients_over_25]
    end
    columns['Veteran Status'] = c_t[:VeteranStatus] if options[:veteran]
    if options[:race]
      HudUtility.races.each do |k, title|
        columns[title] = c_t[k.to_sym]
      end
    end
    columns['Ethnicity'] = c_t[:Ethnicity] if options[:ethnicity]
    columns['Project Type'] = she_t[project_type_col] if options[:project_type]
    columns['Days Homeless Last Three Years'] = wcp_t[:days_homeless_last_three_years] if options[:lot_homeless]
    columns['CoC'] = ec_t[:CoCCode] if options[:coc]
    columns
  end
end
