###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'ClaimsReporting::QualityMeasuresReport', type: :model do
  it 'works' do
    report = ClaimsReporting::QualityMeasuresReport.for_plan_year('2019')

    expect(report.title).to eq('PY2019')
    expect(report.date_range.first).to eq(Date.iso8601('2019-01-01'))
    expect(report.date_range.last).to eq(Date.iso8601('2019-12-31'))

    data = report.serializable_hash

    assert_equal report.title, data[:title]
    assert_equal report.date_range, data[:date_range]
    assert data.keys.include?(:measures)
  end
end
