# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ProjectCeConfig, type: :model do
  let!(:project) { create(:hmis_hud_project) }

  describe 'callbacks' do
    before do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).and_yield
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    it 'calls CandidatePoolBuilder after create when waitlist referrals are supported' do
      create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true)
      expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call)
    end

    it 'does not call CandidatePoolBuilder after create when only direct referrals are supported' do
      create(
        :hmis_project_ce_config,
        project: project,
        supports_waitlist_referrals: false,
        receives_direct_referrals: true,
      )
      expect(Hmis::Ce::Match::CandidatePoolBuilder).not_to have_received(:call)
    end

    it 'calls CandidatePoolBuilder after update when waitlist referrals are supported' do
      config = create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true)

      expect(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
      config.update!(enabled: false)
    end
  end
end
