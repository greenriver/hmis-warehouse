###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PerformanceDashboard::Overview::Detail # rubocop:disable Style/ClassAndModuleChildren
  extend ActiveSupport::Concern

  def detail_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_details(options)
    when :exiting
      exiting_details(options)
    end
  end

  def header_for(options)
    return unless options[:key]

    case options[:key].to_sym
    when :entering
      entering_detail_headers(options)
    when :exiting
      exiting_detail_headers(options)
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

  def yn(boolean)
    boolean ? 'Yes' : 'No'
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
end
