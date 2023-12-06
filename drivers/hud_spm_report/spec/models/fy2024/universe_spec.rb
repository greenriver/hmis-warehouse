###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_enrollment_context'

RSpec.describe 'HUD SPM Universe', type: :model do
  include_context 'FY2024 SPM enrollment context'

  describe 'simple universe' do
    before(:all) do
      setup(:enrollment_universe)
      run(default_filter, nil)
      HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(@report_result)
    end

    it 'creates enrollments' do
      expect(HudSpmReport::Fy2024::SpmEnrollment.count).to eq(6)
    end

    it 'creates an episode' do
      client = GrdaWarehouse::Hud::Client.destination.first
      episode = HudSpmReport::Fy2024::Episode.create(report: @report_result, client: client)
      episode.compute_episode(
        HudSpmReport::Fy2024::SpmEnrollment.where(client_id: client.id).to_a,
        included_project_types: [0, 1, 8],
        excluded_project_types: [3, 4],
        include_self_reported: true,
      )
      expect(episode.first_date).to eq '2021-08-01'.to_date
      expect(episode.last_date).to eq '2022-10-31'.to_date
    end
  end

  describe 'return universe' do
    before(:all) do
      setup(:return_universe)
      run(default_filter, nil)
      HudSpmReport::Fy2024::SpmEnrollment.create_enrollment_set(@report_result)
    end

    it 'computes a return' do
      client = GrdaWarehouse::Hud::Client.destination.first
      return_to_homelessness = HudSpmReport::Fy2024::Return.new(report_instance: @report_result, client: client).compute_return

      expect(return_to_homelessness.return_date).to eq '2022-05-01'.to_date
    end
  end
end
