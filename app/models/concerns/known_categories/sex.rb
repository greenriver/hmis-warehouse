###
# Copyright Green River Data Group, Inc.
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
