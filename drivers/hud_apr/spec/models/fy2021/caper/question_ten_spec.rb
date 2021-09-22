###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'caper_context'

RSpec.describe HudApr::Generators::Caper::Fy2021::QuestionTen, type: :model do
  include_context 'caper context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Caper::Fy2021::QuestionTen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q10a: Gender of Adults' do
    # Tested in the APR
  end

  describe 'Q10b: Gender of Children' do
    # Tested in the APR
  end

  describe 'Q10c: Gender of Persons Missing Age Information' do
    # Tested in the APR
  end

  describe 'Q10d: Gender by Age Ranges' do
    it 'counts < 18' do
      expect(report_result.answer(question: 'Q10d', cell: 'C4').summary).to eq(1)
      expect(report_result.answer(question: 'Q10d', cell: 'C9').summary).to eq(2)
    end

    it 'counts 18..24' do
      expect(report_result.answer(question: 'Q10d', cell: 'D9').summary).to eq(6)
    end

    it 'counts not collected' do
      expect(report_result.answer(question: 'Q10d', cell: 'H5').summary).to eq(1)
      expect(report_result.answer(question: 'Q10d', cell: 'H9').summary).to eq(1)
    end
  end
end
