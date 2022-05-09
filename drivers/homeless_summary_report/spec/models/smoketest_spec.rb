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
    run!(default_filter)
  end

  after(:all) do
    cleanup
  end

  it 'populates the report' do
    expect(report_result.completed_at).not_to eq(nil)
    expect(result(:m1a_es_sh_days, :spm_all_persons__all)).to be >= 1
  end
end
