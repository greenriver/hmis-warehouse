###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisSimulation::Builders::EventBuilder do
  let!(:data_source) { create(:hmis_data_source) }
  let(:user_id) do
    User.setup_system_user
    Hmis::Hud::User.system_user(data_source_id: data_source.id).user_id
  end
  let(:date)       { Date.new(2026, 4, 1) }
  let(:project)    { create(:hmis_hud_project, data_source: data_source, ProjectType: 14) }
  let(:client)     { create(:hmis_hud_client, data_source: data_source) }
  let(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, project: project, client: client) }

  def build(event_code: 3, referral_result: nil, result_date: nil)
    described_class.new(
      enrollment: enrollment,
      date: date,
      event_code: event_code,
      referral_result: referral_result,
      result_date: result_date,
      data_source: data_source,
      user_id: user_id,
    ).build!
  end

  describe '#build!' do
    it 'creates one Event record' do
      expect { build }.to change { Hmis::Hud::Event.where(data_source: data_source).count }.by(1)
    end

    it 'uses a FAKE EventID' do
      expect(build.EventID).to start_with('FAKE')
    end

    it 'sets EventDate to the provided date' do
      expect(build.EventDate).to eq(date)
    end

    it 'sets Event code to the provided code' do
      expect(build(event_code: 4).Event).to eq(4)
    end

    it 'links to the correct enrollment' do
      event = build
      expect(event.EnrollmentID).to eq(enrollment.EnrollmentID)
      expect(event.PersonalID).to eq(enrollment.PersonalID)
    end

    it 'sets ReferralResult when provided' do
      expect(build(referral_result: 1).ReferralResult).to eq(1)
    end

    it 'leaves ReferralResult nil when not provided' do
      expect(build.ReferralResult).to be_nil
    end

    it 'sets ResultDate when provided' do
      expect(build(result_date: date + 5).ResultDate).to eq(date + 5)
    end
  end
end
