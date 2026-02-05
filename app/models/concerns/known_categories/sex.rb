###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module KnownCategories::Sex
  extend ActiveSupport::Concern

  def sex_calculations
    @sex_calculations ||= {}.tap do |calcs|
      HudHelper.util.sexes.each do |key, title|
        calcs[title] = ->(value) { value == key }
      end
      calcs['Missing'] = lambda(&:nil?)
    end
  end

  def standard_sex_calculation
    c_t[:Sex]
  end
end
