###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_context'

RSpec.describe HudSpmReport::Generators::Fy2020::MeasureTwo, type: :model do
  include_context 'HudSpmReport context'

  before(:all) do
    run(default_filter, described_class.question_number)
  end

  it 'parses' do
    assert true, 'code loads OK'
  end

  it 'handles example 2' do
    pp report_result
    puts @user.email
    assert true, 'code loads OK'
  end
end
