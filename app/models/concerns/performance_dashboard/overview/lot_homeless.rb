###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceDashboard::Overview::LotHomeless
  extend ActiveSupport::Concern
  LOT_HOMELESS_BUCKET_TITLES = {
    one_week: '0 - 7 days',
    one_week_to_one_month: '8 - 30 days',
    one_to_two_months: '31 - 60 days',
    two_to_three_months: '61 - 90 days',
    three_to_six_months: '91 - 180 days',
    six_months_to_one_year: '181 - 365 days',
    one_to_two_years: '1 - 2 years',
    over_two_years: '2+ years',
    unknown: 'Unknown',
  }.freeze

  private def lot_homeless_buckets
    LOT_HOMELESS_BUCKET_TITLES.keys
  end

  def lot_homeless_bucket_titles
    LOT_HOMELESS_BUCKET_TITLES
  end

  def lot_homeless_bucket(lot)
    return :unknown unless lot

    if lot < 8
      :one_week
    elsif lot < 31
      :one_week_to_one_month
    elsif lot < 61
      :one_to_two_months
    elsif lot < 91
      :two_to_three_months
    elsif lot < 181
      :three_to_six_months
    elsif lot < 366
      :six_months_to_one_year
    elsif lot < 731
      :one_to_two_years
    elsif lot > 730
      :over_two_years
    else
      :unknown
    end
  end

  def lot_homeless_query(key)
    return '0=1' unless key

    @lot_homeless_queries ||= {
      one_week: wcp_t[:days_homeless_last_three_years].lt(8),
      one_week_to_one_month: wcp_t[:days_homeless_last_three_years].between(8..30),
      one_to_two_months: wcp_t[:days_homeless_last_three_years].between(31..60),
      two_to_three_months: wcp_t[:days_homeless_last_three_years].between(61..90),
      three_to_six_months: wcp_t[:days_homeless_last_three_years].between(91..180),
      six_months_to_one_year: wcp_t[:days_homeless_last_three_years].between(181..365),
      one_to_two_years: wcp_t[:days_homeless_last_three_years].between(366..730),
      over_two_years: wcp_t[:days_homeless_last_three_years].gt(730),
      unknown: wcp_t[:days_homeless_last_three_years].eq(nil),
    }
    @lot_homeless_queries[key.to_sym]
  end
end
