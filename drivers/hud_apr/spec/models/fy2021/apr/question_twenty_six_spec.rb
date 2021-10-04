###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionTwentySix, type: :model do
  include_context 'apr context FY2021'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionTwentySix::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # This is just a smoke test, the underlying logic should already have been tested
  it 'runs' do
    expect(report_result.answer(question: 'Q26a', cell: 'B2').summary).to eq(1)
  end

  describe 'Q26a: Chronic Homeless Status - Number of Households w/at least one or more CH person' do
  end

  describe 'Q26b: Number of Chronically Homeless Persons by Household' do
  end

  describe 'Q26c: Gender of Chronically Homeless Persons' do
  end

  describe 'Q26d: Age of Chronically Homeless Persons' do
  end

  describe 'Q26e: Physical and Mental Health Conditions - Chronically Homeless Persons' do
  end

  describe 'Q26f: Client Cash Income - Chronically Homeless Persons' do
  end

  describe 'Q26g: Type of Cash Income Sources - Chronically Homeless Persons' do
  end

  describe 'Q26h: Type of Non-Cash Benefit Sources - Chronically Homeless Persons' do
  end
end
