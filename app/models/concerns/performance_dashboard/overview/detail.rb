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

  def support_title(key:, sub_key: nil, breakdown:)
    title = 'Clients'
    title += " #{sub_key.to_s.humanize.titleize}" if sub_key
    title += " #{key.to_s.titleize} #{breakdown}"
    title
  end
end
