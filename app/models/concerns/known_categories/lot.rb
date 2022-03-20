###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Lot
  extend ActiveSupport::Concern

  def lot_calculations
    @lot_calculations ||= {}.tap do |calcs|
      calcs['0 - 7 days'] = ->(value) { value == '0 - 7 days' }
      calcs['8 - 30 days'] = ->(value) { value == '8 - 30 days' }
      calcs['31 - 60 days'] = ->(value) { value == '31 - 60 days' }
      calcs['61 - 90 days'] = ->(value) { value == '61 - 90 days' }
      calcs['91 - 180 days'] = ->(value) { value == '91 - 180 days' }
      calcs['181 - 365 days'] = ->(value) { value == '181 - 365 days' }
      calcs['1 - 2 years'] = ->(value) { value == '1 - 2 years' }
      calcs['2+ years'] = ->(value) { value == '2+ years' }
      calcs['Unknown'] = ->(value) { value == 'Unknown' }
    end
  end

  def standard_lot_calculation
    conditions = [
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
    acase(conditions, elsewise: '99')
  end
end
