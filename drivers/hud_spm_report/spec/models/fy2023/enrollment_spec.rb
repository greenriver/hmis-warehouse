###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_enrollment_context'

RSpec.describe HudSpmReport::Fy2023::Enrollment, type: :model do
  include_context 'FY2023 SPM enrollment context'

  before(:all) do
    setup(:enrollment_universe)
    run(default_filter, nil)
    HudSpmReport::Fy2023::Enrollment.create_enrollment_set(@report_result)
  end

  it 'creates enrollments' do
    expect(HudSpmReport::Fy2023::Enrollment.count).to eq(6)
  end
end
