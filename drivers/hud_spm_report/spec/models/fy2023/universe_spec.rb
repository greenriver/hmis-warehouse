###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_enrollment_context'

RSpec.describe 'HUD SPM Universe', type: :model do
  include_context 'FY2023 SPM enrollment context'

  before(:all) do
    setup(:enrollment_universe)
    run(default_filter, nil)
    HudSpmReport::Fy2023::Enrollment.create_enrollment_set(@report_result)
  end

  it 'creates enrollments' do
    expect(HudSpmReport::Fy2023::Enrollment.count).to eq(6)
  end

  it 'creates episode' do
    client = GrdaWarehouse::Hud::Client.destination.first
    episode = HudSpmReport::Fy2023::Episode.create(report: @report_result, client: client)
    episode.compute_episode([0, 1, 8], [3, 4])
    expect(episode).to be_present
  end
end
