###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::LotThreeYears
  extend ActiveSupport::Concern

  def lot_three_years_calculations
    @lot_three_years_calculations ||= {}.tap do |calcs|
      lot_three_years_categories.each do |_, title|
        calcs[title] = ->(value) { value == title }
      end
    end
  end

  private def lot_three_years_categories
    [
      [wcp_t[:days_homeless_last_three_years].lt(8), '0 - 7 days'],
      [wcp_t[:days_homeless_last_three_years].between(8..30), '8 - 30 days'],
      [wcp_t[:days_homeless_last_three_years].between(31..60), '31 - 60 days'],
      [wcp_t[:days_homeless_last_three_years].between(61..90), '61 - 90 days'],
      [wcp_t[:days_homeless_last_three_years].between(91..180), '91 - 180 days'],
      [wcp_t[:days_homeless_last_three_years].between(181..365), '181 - 365 days'],
      [wcp_t[:days_homeless_last_three_years].between(366..730), '1 - 2 years'],
      [wcp_t[:days_homeless_last_three_years].gt(730), '2+ years'],
      [wcp_t[:days_homeless_last_three_years].eq(nil), 'Unknown'],
    ]
  end

  def standard_lot_three_years_calculation
    acase(lot_three_years_categories, elsewise: '99')
  end
end
