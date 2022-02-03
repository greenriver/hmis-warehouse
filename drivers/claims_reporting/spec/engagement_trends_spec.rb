###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe 'ClaimsReporting::EngagementTrends', type: :model do
  let(:user) { create :user }

  test_races = ['BlackAfAmerican', 'MultiRacial']
  test_age_range = 'forty_to_forty_nine'
  test_ethnicity = 1
  test_gender =  2
  test_aco = 3
  standard_options = {
    cohort_type: :selected_period,
    races: test_races,
    ethnicities: [test_ethnicity],
    genders: [test_gender],
    age_ranges: [test_age_range],
    acos: [test_aco],
  }

  it 'can calculate with cohort_type selected_period' do
    report = ClaimsReporting::EngagementTrends.new(
      user: user,
      options: standard_options.merge(cohort_type: :selected_period),
    )
    report.calculate
    data = report.results

    expect(data).to be_kind_of(Hash)
  end

  it 'can calculate cohort_type engaged_history' do
    report = ClaimsReporting::EngagementTrends.new(
      user: user,
      options: standard_options.merge(cohort_type: :engaged_history),
    )
    report.calculate
    data = report.results
    expect(data).to be_kind_of(Hash)
  end
end
