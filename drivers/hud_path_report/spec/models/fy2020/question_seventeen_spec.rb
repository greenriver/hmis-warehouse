###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2020::QuestionSeventeen, type: :model do
  include_context 'path context'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2020::QuestionSeventeen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  it 'counts community mental health' do
    expect(report_result.answer(question: 'Q17', cell: 'B6').summary).to eq(1)
  end

  it 'counts case management' do
    expect(report_result.answer(question: 'Q17', cell: 'B8').summary).to eq(1)
  end

  it 'others are zero' do
    (2..14).each do |row|
      next if [6, 8].include?(row)

      expect(report_result.answer(question: 'Q17', cell: 'B' + row.to_s).summary).to eq(0)
    end
  end
end
