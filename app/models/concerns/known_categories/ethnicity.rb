###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Ethnicity
  extend ActiveSupport::Concern

  def ethnicity_calculations
    @ethnicity_calculations ||= {}.tap do |calcs|
      HUD.ethnicities.each do |key, title|
        calcs[title] = ->(value) { value == key }
      end
    end
  end

  def standard_ethnicity_calculation
    c_t[:Ethnicity]
  end
end
