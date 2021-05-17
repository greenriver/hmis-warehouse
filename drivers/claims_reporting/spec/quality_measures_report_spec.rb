###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe ClaimsReporting::QualityMeasuresReport, type: :model do
  it 'can calculate with basic filters' do
    date_range = Date.iso8601('2019-01-01')..Date.iso8601('2019-12-31')
    test_race = 'BlackAfAmerican'
    test_age_range = 'forty_to_forty_nine'
    test_ethnicity = 1
    test_gender =  2
    test_aco = 3

    report = ClaimsReporting::QualityMeasuresReport.new(
      date_range: date_range,
      filter: Filters::QualityMeasuresFilter.new(
        races: [test_race],
        ethnicities: [test_ethnicity],
        genders: [test_gender],
        age_ranges: [test_age_range],
        acos: [test_aco],
      ),
    )
    data = report.serializable_hash

    expect(data).to be_kind_of(Hash)

    assert data.keys.include?(:measures)
  end
end
