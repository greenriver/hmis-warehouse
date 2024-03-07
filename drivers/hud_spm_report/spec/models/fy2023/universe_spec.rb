###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'spm_enrollment_context'

RSpec.describe 'HUD SPM Universe', type: :model do
  include_context 'FY2023 SPM enrollment context'

  describe 'simple universe' do
    before(:all) do
      setup(:enrollment_universe)
      filter = default_filter.update(project_ids: GrdaWarehouse::Hud::Project.pluck(:id))
      run(filter, nil)
      HudSpmReport::Fy2023::SpmEnrollment.create_enrollment_set(@report_result)
    end

    it 'creates enrollments' do
      expect(HudSpmReport::Fy2023::SpmEnrollment.count).to eq(6)
    end

    it 'creates an episode' do
      client = GrdaWarehouse::Hud::Client.destination.first
      episode = HudSpmReport::Fy2023::Episode.create(report: @report_result, client: client)
      episode.compute_episode(
        HudSpmReport::Fy2023::SpmEnrollment.where(client_id: client.id).to_a,
        included_project_types: [0, 1, 8],
        excluded_project_types: [2],
        include_self_reported_and_ph: true,
      )
      aggregate_failures do
        expect(episode.first_date).to eq '2022-02-01'.to_date
        expect(episode.last_date).to eq '2022-09-01'.to_date
      end
    end
  end

  describe 'return universe' do
    before(:all) do
      setup(:return_universe)
      filter = default_filter.update(project_ids: GrdaWarehouse::Hud::Project.pluck(:id))
      run(filter, nil)
      HudSpmReport::Fy2023::SpmEnrollment.create_enrollment_set(@report_result)
    end

    it 'computes a return' do
      client = GrdaWarehouse::Hud::Client.destination.first
      enrollments = HudSpmReport::Fy2023::SpmEnrollment.all
      return_to_homelessness = HudSpmReport::Fy2023::Return.new(report_instance: @report_result, client: client).compute_return(enrollments)

      expect(return_to_homelessness.return_date).to eq '2022-05-01'.to_date
    end
  end
end
