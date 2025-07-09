# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::CandidatePoolBuilder do
  let!(:organization) { create :hmis_hud_organization }
  let!(:project) { create :hmis_hud_project, organization: organization }
  let!(:opportunity) { create(:hmis_ce_opportunity, project: project, data_source: project.data_source) }
  let(:builder) { described_class.new(Hmis::Ce::Opportunity.active) }

  describe '#perform' do
    context 'with active opportunities' do
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: organization) }
      let!(:rule2) { create(:hmis_ce_priority_scheme, owner: organization) }

      before do
        allow_any_instance_of(Hmis::Ce::Match::Rule).to receive(:applies_to_entity?).and_return(true)
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'creates pools based on unique rule combinations' do
        expect { builder.perform }.to change(Hmis::Ce::Match::CandidatePool, :count).by(1)
      end

      it 'assigns opportunities to appropriate pools' do
        builder.perform
        pool = Hmis::Ce::Match::CandidatePool.last
        expect(opportunity.reload.candidate_pool).to eq(pool)
      end
    end

    context 'with orphaned candidate pools' do
      let(:expiration_days) { 30 }
      let!(:old_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, created_at: (expiration_days + 1).days.ago)
      end
      let!(:new_orphaned_pool) do
        create(:hmis_ce_match_candidate_pool, created_at: (expiration_days - 1).days.ago)
      end
      let!(:active_pool) { create(:hmis_ce_match_candidate_pool, created_at: (expiration_days + 1).days.ago) }
      let!(:opportunity_with_pool) { create(:hmis_ce_opportunity, candidate_pool: active_pool) }

      before do
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:days_to_retain_orphan_candidate_pools).and_return(expiration_days)
        allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      end

      it 'deletes old orphaned pools but not new or active ones' do
        expect { builder.send(:cleanup_orphan_pools) }.to change(Hmis::Ce::Match::CandidatePool, :count).by(-1)
        expect(Hmis::Ce::Match::CandidatePool.exists?(old_orphaned_pool.id)).to be_falsey
        expect(Hmis::Ce::Match::CandidatePool.exists?(new_orphaned_pool.id)).to be_truthy
        expect(Hmis::Ce::Match::CandidatePool.exists?(active_pool.id)).to be_truthy
      end
    end

    context 'when passed specific opportunities' do
      let!(:opportunity2) { create(:hmis_ce_opportunity, project: project, data_source: project.data_source) }
      let(:builder) { described_class.new(Hmis::Ce::Opportunity.where(id: [opportunity2.id])) }

      it 'does not impact the non-included opportunity' do
        expect do
          builder.perform
          opportunity.reload
          opportunity2.reload
        end.to change(opportunity2, :candidate_pool).from(nil).
          and not_change(opportunity, :candidate_pool).from(nil)
      end
    end
  end

  describe 'locking behavior' do
    it 'acquires an advisory lock' do
      expect(GrdaWarehouseBase).to receive(:with_advisory_lock).
        with('CandidatePoolBuilder', timeout_seconds: 30).
        and_call_original

      builder.perform
    end

    it 'wraps operations in a transaction' do
      expect(Hmis::Ce::Match::CandidatePool).to receive(:transaction)
      builder.perform
    end
  end

  describe 'when there are many rules' do
    before do
      50.times { create(:hmis_ce_eligibility_requirement, owner: opportunity) }
      50.times { create(:hmis_ce_eligibility_requirement, owner: project) }
      50.times { create(:hmis_ce_eligibility_requirement, owner: organization) }
    end

    it 'queries the db a reasonable amount' do
      expect do
        builder.perform
      end.to make_database_queries(count: 10..20)
    end
  end
end
