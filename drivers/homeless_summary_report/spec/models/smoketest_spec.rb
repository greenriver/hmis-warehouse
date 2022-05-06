###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'report_context'

RSpec.describe HomelessSummaryReport::Report, type: :model do
  include_context 'report context'

  before(:all) do
    setup(default_setup_path)
  end

  after(:all) do
    cleanup
  end

  it 'populates the report' do
    run!(default_filter)
    expect(report_result.completed_at).not_to eq(nil)
  end
end
