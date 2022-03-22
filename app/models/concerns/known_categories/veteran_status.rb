###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::VeteranStatus
  extend ActiveSupport::Concern

  def veteran_status_calculations
    @veteran_status_calculations ||= {}.tap do |calcs|
      HUD.no_yes_reasons_for_missing_data_options.each do |key, title|
        calcs["Veteran Status #{title}"] = ->(value) { value == key }
      end
    end
  end

  def standard_veteran_status_calculation
    c_t[:VeteranStatus]
  end
end
