# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::ProjectCeConfig, type: :model do
  let!(:project) { create(:hmis_hud_project) }
  let!(:waitlist_config) { create(:hmis_project_ce_config, project: project, supports_waitlist_referrals: true) }

  describe 'callbacks' do
    before do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).and_yield
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    it 'calls CandidatePoolBuilder after create when waitlist referrals are supported' do
      create(:hmis_project_ce_config, project: create(:hmis_hud_project), supports_waitlist_referrals: true)
      expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call)
    end

    it 'does not call CandidatePoolBuilder after create when only direct referrals are supported' do
      create(
        :hmis_project_ce_config,
        project: create(:hmis_hud_project),
        supports_waitlist_referrals: false,
        receives_direct_referrals: true,
      )
      expect(Hmis::Ce::Match::CandidatePoolBuilder).not_to have_received(:call)
    end

    context 'on update' do
      it 'calls CandidatePoolBuilder when waitlist referrals are supported' do
        waitlist_config.update!(enabled: false)
        expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call)
      end

      it 'does not call CandidatePoolBuilder when only direct referrals are supported' do
        direct_config = create(
          :hmis_project_ce_config,
          project: create(:hmis_hud_project),
          supports_waitlist_referrals: false,
          receives_direct_referrals: true,
        )
        direct_config.update!(enabled: false)
        expect(Hmis::Ce::Match::CandidatePoolBuilder).not_to have_received(:call)
      end
    end
  end
end
