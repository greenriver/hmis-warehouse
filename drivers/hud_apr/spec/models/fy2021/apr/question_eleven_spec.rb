###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'apr_context'

RSpec.describe HudApr::Generators::Apr::Fy2021::QuestionEleven, type: :model do
  include_context 'apr context'

  before(:all) do
    default_setup
    run(default_filter, HudApr::Generators::Apr::Fy2021::QuestionEleven::QUESTION_NUMBER)
  end

  after(:all) do
    cleanup
  end

  describe 'Q11: Age' do
    it 'counts clients in households with adults and children' do
      expect(report_result.answer(question: 'Q11', cell: 'D13').summary).to eq(2)
    end
  end
end
