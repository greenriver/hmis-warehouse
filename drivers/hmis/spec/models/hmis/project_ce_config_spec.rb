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
        waitlist_config.update!(receives_direct_referrals: true)
        expect(Hmis::Ce::Match::CandidatePoolBuilder).to have_received(:call)
      end

      it 'does not call CandidatePoolBuilder when only direct referrals are supported' do
        direct_config = create(
          :hmis_project_ce_config,
          project: create(:hmis_hud_project),
          supports_waitlist_referrals: false,
          receives_direct_referrals: true,
        )
        direct_config.update!(receives_direct_referrals_from: [project.id])
        expect(Hmis::Ce::Match::CandidatePoolBuilder).not_to have_received(:call)
      end
    end
  end

  describe '#receives_direct_referrals_from=' do
    let!(:receiving_project) { create(:hmis_hud_project) }
    let!(:sending_project) { create(:hmis_hud_project, data_source: receiving_project.data_source) }
    # Waitlist referrals off, so these examples don't trigger the candidate pool rebuild.
    let!(:config) do
      create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: true,
        supports_waitlist_referrals: false,
      )
    end

    it 'casts string ids to integers, since enforcement compares against project primary keys' do
      config.update!(receives_direct_referrals_from: [sending_project.id.to_s])

      expect(config.reload.receives_direct_referrals_from).to eq([sending_project.id])
    end

    it 'leaves integer ids as they are' do
      config.update!(receives_direct_referrals_from: [sending_project.id])

      expect(config.reload.receives_direct_referrals_from).to eq([sending_project.id])
    end

    it 'stores nil for any value that contains no usable ids' do
      [[], nil, [''], [nil], ['  ']].each do |blank|
        config.update!(receives_direct_referrals_from: [sending_project.id])
        config.update!(receives_direct_referrals_from: blank)

        expect(config.reload.receives_direct_referrals_from).to be_nil, "expected #{blank.inspect} to clear the allowlist"
      end
    end

    # An absent key and a null one read the same, but the admin config table renders a row per key
    # present, so a null would show up as a labeled blank.
    it 'removes the key entirely when cleared, rather than storing null' do
      config.update!(receives_direct_referrals_from: [sending_project.id])
      config.update!(receives_direct_referrals_from: [])

      expect(JSON.parse(config.reload.config_options)).not_to have_key('receives_direct_referrals_from')
    end

    it 'drops non-numeric ids rather than coercing them to project 0' do
      config.update!(receives_direct_referrals_from: [sending_project.id.to_s, 'abc'])

      expect(config.reload.receives_direct_referrals_from).to eq([sending_project.id])
    end

    it 'does not disturb the other CE config options' do
      config.update!(receives_direct_referrals_from: [sending_project.id])
      config.reload

      expect(config.receives_direct_referrals?).to eq(true)
      expect(config.supports_waitlist_referrals?).to eq(false)
    end
  end

  describe 'clearing the allowlist when the project does not receive direct referrals' do
    before do
      allow(Hmis::Ce::Match::CandidatePool).to receive(:lock_for_maintenance!).and_yield
      allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    end

    let!(:receiving_project) { create(:hmis_hud_project) }
    let!(:sending_project) { create(:hmis_hud_project, data_source: receiving_project.data_source) }

    it 'clears an existing allowlist when direct referrals are turned off' do
      config = create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: true,
        supports_waitlist_referrals: true,
        receives_direct_referrals_from: [sending_project.id],
      )
      expect(config.receives_direct_referrals_from).to eq([sending_project.id])

      config.update!(receives_direct_referrals: false)

      expect(config.reload.receives_direct_referrals_from).to be_nil
      expect(JSON.parse(config.config_options)).not_to have_key('receives_direct_referrals_from')
    end

    it 'preserves the allowlist across an unrelated save while direct referrals stay on' do
      config = create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: true,
        supports_waitlist_referrals: false,
        receives_direct_referrals_from: [sending_project.id],
      )

      config.update!(supports_waitlist_referrals: true)

      expect(config.reload.receives_direct_referrals_from).to eq([sending_project.id])
    end

    # The CSV importer assigns the allowlist independently of the receives flag, so it can write one
    # onto a waitlist-only config. Clearing it here is a deliberate change to that importer behavior.
    it 'clears an allowlist assigned to a config that only supports waitlist referrals' do
      config = create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: false,
        supports_waitlist_referrals: true,
        receives_direct_referrals_from: [sending_project.id],
      )

      expect(config.receives_direct_referrals_from).to be_nil
    end

    it 'does not add the key to a config that never had an allowlist' do
      config = create(
        :hmis_project_ce_config,
        project: receiving_project,
        receives_direct_referrals: false,
        supports_waitlist_referrals: true,
      )

      expect(JSON.parse(config.config_options)).not_to have_key('receives_direct_referrals_from')
    end
  end
end
