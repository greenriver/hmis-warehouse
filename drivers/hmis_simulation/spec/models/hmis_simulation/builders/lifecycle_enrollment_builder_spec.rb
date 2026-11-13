###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::LifecycleEnrollmentBuilder do
  include_context 'hmis simulation builder setup'

  let(:date)       { Date.current - 5 }
  let(:opens_on)   { date - 3 }
  let(:ce_project) { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }

  subject(:builder) do
    described_class.new(
      client: client,
      lifecycle_name: 'ce',
      ce_project: ce_project,
      opens_on: opens_on,
      coc_code: 'XX-500',
      data_source: data_source,
      user_id: user_id,
    )
  end

  describe '#build!' do
    it 'creates an Hmis::Hud::Enrollment for the CE project' do
      expect { builder.build! }.to change { Hmis::Hud::Enrollment.where(data_source: data_source).count }.by(1)
    end

    it 'creates an HmisSimulation::LifecycleEnrollment state record' do
      expect { builder.build! }.to change { HmisSimulation::LifecycleEnrollment.where(data_source_id: data_source.id).count }.by(1)
    end

    it 'sets EntryDate to opens_on (backdated)' do
      builder.build!
      enrollment = Hmis::Hud::Enrollment.where(data_source: data_source).last
      expect(enrollment.EntryDate).to eq(opens_on)
    end

    it 'uses a FAKE EnrollmentID' do
      builder.build!
      expect(Hmis::Hud::Enrollment.where(data_source: data_source).last.EnrollmentID).to start_with('FAKE')
    end

    it 'sets the lifecycle state to open' do
      builder.build!
      state = HmisSimulation::LifecycleEnrollment.find_by(
        data_source_id: data_source.id,
        hud_client_id: client.id,
      )
      expect(state.status).to eq('open')
    end

    it 'sets lifecycle_name on the state record' do
      builder.build!
      state = HmisSimulation::LifecycleEnrollment.find_by(data_source_id: data_source.id, hud_client_id: client.id)
      expect(state.lifecycle_name).to eq('ce')
    end

    it 'sets opens_on on the state record' do
      builder.build!
      state = HmisSimulation::LifecycleEnrollment.find_by(data_source_id: data_source.id, hud_client_id: client.id)
      expect(state.opens_on).to eq(opens_on)
    end
  end
end
