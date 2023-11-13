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
    episode.compute_episode(included_project_types: [0, 1, 8], excluded_project_types: [3, 4], include_self_reported: true)
    expect(episode.first_date).to eq '2021-08-01'.to_date
    expect(episode.last_date).to eq '2022-10-31'.to_date
  end
end
