###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Lot
  extend ActiveSupport::Concern

  def lot_calculations
    @lot_calculations ||= {}.tap do |calcs|
      lot_categories.each do |_, title|
        calcs[title] = ->(value) { value == title }
      end
    end
  end

  private def lot_categories
    [
      [wcp_t[:homeless_days].lt(8), '0 - 7 days'],
      [wcp_t[:homeless_days].between(8..30), '8 - 30 days'],
      [wcp_t[:homeless_days].between(31..60), '31 - 60 days'],
      [wcp_t[:homeless_days].between(61..90), '61 - 90 days'],
      [wcp_t[:homeless_days].between(91..180), '91 - 180 days'],
      [wcp_t[:homeless_days].between(181..365), '181 - 365 days'],
      [wcp_t[:homeless_days].between(366..730), '1 - 2 years'],
      [wcp_t[:homeless_days].gt(730), '2+ years'],
      [wcp_t[:homeless_days].eq(nil), 'Unknown'],
    ]
  end

  def standard_lot_calculation
    acase(lot_categories, elsewise: '99')
  end
end
