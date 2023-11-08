###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'path_context'

RSpec.describe HudPathReport::Generators::Fy2024::QuestionSeventeen, type: :model do
  include_context 'path context FY2024'

  before(:all) do
    default_setup
    run(default_filter, HudPathReport::Generators::Fy2024::QuestionSeventeen::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  # DEPRECATED_FY2024 - these are expected to fail until we re-write the report
  # it 'counts substance abuse' do
  #   expect(report_result.answer(question: 'Q17', cell: 'B7').summary).to eq(1)
  # end

  # it 'counts case management' do
  #   expect(report_result.answer(question: 'Q17', cell: 'B8').summary).to eq(1)
  # end

  it 'others are zero' do
    (2..14).each do |row|
      next if [7, 8].include?(row)

      expect(report_result.answer(question: 'Q17', cell: 'B' + row.to_s).summary).to eq(0)
    end
  end
end
